#!/usr/bin/env python3
"""Translate valid Sanskrit bhashya to English and Hindi with Gemini.

Skips placeholders, copy-forward duplicates, and empty rows.
Writes JSON only to lib/data/scripts/source/bhashya/ (never touches SQLite).
Run lib/data/scripts/generate_full_db_v7.py to build geeta_v7.db.

Usage:
  python3 scripts/bhashya_translate_gemini.py --estimate
  python3 scripts/bhashya_translate_gemini.py
  python3 scripts/bhashya_translate_gemini.py --limit 4
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import re
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_ROOT = ROOT / "lib/data/scripts"
CHAPTER_JSON_PATTERN = str(SCRIPTS_ROOT / "source/chapters/gita_chapter_*.json")
ENV = ROOT / ".env"
PROGRESS = ROOT / "scripts" / "bhashya_gemini_progress.jsonl"
STATE = ROOT / "scripts" / "bhashya_gemini_state.json"
OUT_DIR = SCRIPTS_ROOT / "source/bhashya"

AUTHORS = [
    "Shankaracharya (Sanskrit)",
    "Ramanujacharya (Sanskrit)",
    "Madhvacharya (Sanskrit)",
]
LANGS = ["en", "hi"]
LANG_NAME = {"en": "English", "hi": "Hindi (Devanagari)"}

PLACEHOLDER_RE = re.compile(
    r"did not comment|similar|तुल्यत्वार्थ उक्तः पुरस्तात्",
    re.I,
)

SYSTEM = """You are a scholarly translator of classical Vedanta bhashya.

Translate the Sanskrit commentary into the requested language.

Rules:
- Translate what the acharya wrote. Do not summarize. Do not modernize. Do not add life advice.
- Keep word-glosses, quotations, objections, and the argument order.
- Keep technical terms (atman, brahman, yoga, kshema, ananya, maya, bhakti, jnana) with a short gloss in parentheses on first use if needed.
- Do not mix Advaita, Vishishtadvaita, or Dvaita. Translate THIS commentary only.
- Translate the complete bhashya. Do not stop mid-sentence or omit the closing.
- Output only the translation as readable paragraphs. No preamble, no JSON, no title."""

# Gemini 2.5 Flash paid list prices (USD / 1M tokens), Aug 2026.
PRICE_IN = 0.30
PRICE_OUT = 2.50


def load_env(path: Path) -> dict[str, str]:
    if not path.exists():
        raise SystemExit(f"Missing {path}")
    vals: dict[str, str] = {}
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        vals[key.strip()] = value.strip().strip('"').strip("'")
    return vals


def is_placeholder(text: str) -> bool:
    t = (text or "").strip()
    if not t:
        return True
    return bool(PLACEHOLDER_RE.search(t))


def job_key(sid: str, author: str, lang: str) -> str:
    return f"{sid}|{author}|{lang}"


def job_filename(sid: str, author: str, lang: str) -> str:
    safe = re.sub(r"[^A-Za-z0-9]+", "_", author).strip("_")
    return f"{sid}__{safe}__{lang}.json"


def fsync_dir(path: Path) -> None:
    fd = os.open(str(path), os.O_RDONLY)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def atomic_write_json(path: Path, obj: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".tmp")
    payload = json.dumps(obj, ensure_ascii=False, indent=2) + "\n"
    with tmp.open("w", encoding="utf-8") as f:
        f.write(payload)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, path)
    fsync_dir(path.parent)


def append_jsonl(path: Path, row: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    line = json.dumps(row, ensure_ascii=False) + "\n"
    with path.open("a", encoding="utf-8") as f:
        f.write(line)
        f.flush()
        os.fsync(f.fileno())


def iter_saved_rows() -> list[dict]:
    rows: list[dict] = []
    seen: set[str] = set()
    if OUT_DIR.exists():
        for p in sorted(OUT_DIR.glob("*.json")):
            if p.name.endswith(".tmp"):
                continue
            try:
                row = json.loads(p.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError):
                continue
            if not isinstance(row, dict):
                continue
            key = job_key(row.get("id", ""), row.get("author", ""), row.get("lang", ""))
            if key in seen:
                continue
            seen.add(key)
            rows.append(row)
    if PROGRESS.exists():
        for line in PROGRESS.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            if not isinstance(row, dict):
                continue
            key = job_key(row.get("id", ""), row.get("author", ""), row.get("lang", ""))
            if key in seen:
                continue
            seen.add(key)
            rows.append(row)
    return rows


def load_done() -> tuple[set[str], dict]:
    done: set[str] = set()
    prompt = output = 0
    usd = 0.0
    ok = fail = 0
    last = ""
    for row in iter_saved_rows():
        key = job_key(row.get("id", ""), row.get("author", ""), row.get("lang", ""))
        if row.get("ok") and row.get("text"):
            done.add(key)
            ok += 1
            last = f"{row.get('id')} {row.get('author')} {row.get('lang')}"
            usage = row.get("usage") or {}
            in_tok = int(usage.get("promptTokenCount") or 0)
            out_tok = int(usage.get("candidatesTokenCount") or 0) + int(
                usage.get("thoughtsTokenCount") or 0
            )
            prompt += in_tok
            output += out_tok
            usd += (in_tok / 1_000_000) * PRICE_IN + (out_tok / 1_000_000) * PRICE_OUT
        elif row.get("ok") is False:
            fail += 1
    return done, {
        "ok": ok,
        "fail": fail,
        "prompt_tokens": prompt,
        "output_tokens": output,
        "usd": round(usd, 4),
        "last": last,
    }


def persist_result(row: dict) -> None:
    """Disk first (power-cut safe), then the caller may write SQLite."""
    if row.get("id") and row.get("author") and row.get("lang"):
        atomic_write_json(
            OUT_DIR / job_filename(row["id"], row["author"], row["lang"]),
            row,
        )
    append_jsonl(PROGRESS, row)


def backfill_out_dir() -> int:
    """Copy already-saved JSONL rows into per-job JSON files."""
    if not PROGRESS.exists():
        return 0
    n = 0
    for line in PROGRESS.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not row.get("ok") or not row.get("text"):
            continue
        path = OUT_DIR / job_filename(row["id"], row["author"], row["lang"])
        if path.exists():
            continue
        atomic_write_json(path, row)
        n += 1
    return n


def save_state(state: dict) -> None:
    atomic_write_json(STATE, state)


def http_json(url: str, payload: dict, headers: dict, timeout: int = 180) -> dict:
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {e.code}: {body[:900]}") from e


def gemini_translate(
    key: str,
    model: str,
    prompt: str,
    max_output_tokens: int,
) -> tuple[str, dict, str]:
    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"{model}:generateContent?key={key}"
    )
    payload = {
        "systemInstruction": {"parts": [{"text": SYSTEM}]},
        "contents": [{"role": "user", "parts": [{"text": prompt}]}],
        "generationConfig": {
            "temperature": 0.2,
            "maxOutputTokens": max_output_tokens,
            "thinkingConfig": {"thinkingBudget": 0},
        },
    }
    resp = http_json(url, payload, {"Content-Type": "application/json"})
    cand = (resp.get("candidates") or [{}])[0]
    finish = cand.get("finishReason") or ""
    parts = cand.get("content", {}).get("parts") or []
    text = "".join(p.get("text", "") for p in parts if not p.get("thought")).strip()
    usage = resp.get("usageMetadata") or {}
    if not text:
        raise RuntimeError(f"empty Gemini response finish={finish} usage={usage}")
    return text, usage, finish


def build_prompt(verse: dict, author: str, lang: str, bhashya: str) -> str:
    return f"""Target language: {LANG_NAME[lang]}
Acharya: {author.replace(" (Sanskrit)", "")}
Verse: BG {verse["id"]}
Mula: {verse["shloka"]}
Anvaya (context only): {verse["anvay"]}

Sanskrit bhashya to translate:
{bhashya}"""


def collect_jobs() -> tuple[list[dict], dict]:
    json_files = sorted(glob.glob(CHAPTER_JSON_PATTERN))
    if not json_files:
        raise SystemExit(f"No chapter JSON matched {CHAPTER_JSON_PATTERN}")

    jobs: list[dict] = []
    skip = {"placeholder": 0, "copy_forward": 0}
    prev_by_author: dict[str, str | None] = {a: None for a in AUTHORS}
    valid_chars = 0
    prompt_chars = 0
    long_jobs = 0

    for json_file in json_files:
        with open(json_file, "r", encoding="utf-8") as f:
            chapter_data = json.load(f)
        for item in chapter_data:
            ch = item["chapter"]
            sl = item["shloka"]
            sid = f"{ch}.{sl}"
            content = item.get("content", {})
            mool = content.get("Mool Shloka", "") or ""
            anvay = content.get("Anvay", "") or ""
            verse = {"id": sid, "shloka": mool, "anvay": anvay}
            comm_sec = content.get("Commentaries", {})
            for _group, authors in comm_sec.items():
                for author, data in authors.items():
                    if author not in AUTHORS:
                        continue
                    text = (data if isinstance(data, str) else "").strip()
                    reason = None
                    if is_placeholder(text):
                        reason = "placeholder"
                    elif prev_by_author[author] is not None and text == prev_by_author[author]:
                        reason = "copy_forward"
                    prev_by_author[author] = text
                    if reason:
                        skip[reason] += 1
                        continue

                    valid_chars += len(text)
                    if len(text) > 1500:
                        long_jobs += 1
                    for lang in LANGS:
                        prompt = build_prompt(verse, author, lang, text)
                        prompt_chars += len(SYSTEM) + len(prompt)
                        jobs.append(
                            {
                                "id": sid,
                                "author": author,
                                "lang": lang,
                                "sanskrit": text,
                                "prompt": prompt,
                            }
                        )

    stats = {
        "valid_commentaries": len(jobs) // 2,
        "translation_jobs": len(jobs),
        "skipped": skip,
        "valid_chars": valid_chars,
        "prompt_chars_both": prompt_chars,
        "long_bhashyas": long_jobs,
    }
    return jobs, stats


def estimate_cost(stats: dict) -> dict:
    # Devanagari-heavy input ~2.2 chars/token; English output ~4; Hindi ~2.2.
    input_tokens = stats["prompt_chars_both"] / 2.2
    out_en = stats["valid_chars"] * 1.7 / 4.0
    out_hi = stats["valid_chars"] * 1.5 / 2.2
    output_tokens = out_en + out_hi
    retries = 1.12  # truncation retries + 429 repeats
    in_tok = input_tokens * retries
    out_tok = output_tokens * retries
    usd = (in_tok / 1_000_000) * PRICE_IN + (out_tok / 1_000_000) * PRICE_OUT
    thinking_on = usd + (stats["translation_jobs"] * 800 / 1_000_000) * PRICE_OUT * retries
    return {
        "model": "gemini-2.5-flash",
        "prices_usd_per_m": {"input": PRICE_IN, "output": PRICE_OUT},
        "est_input_tokens": int(in_tok),
        "est_output_tokens": int(out_tok),
        "est_usd_thinking_off": round(usd, 2),
        "est_usd_thinking_on_ballpark": round(thinking_on, 2),
        "low_usd": round(usd * 0.75, 2),
        "high_usd": round(usd * 1.6, 2),
        "note": "thinkingBudget=0. Output price includes any leftover thinking tokens.",
    }


def looks_truncated(source: str, out: str, finish: str) -> bool:
    if finish == "MAX_TOKENS":
        return True
    if len(source) < 400:
        return False
    return len(out) < 0.45 * len(source)


def run(limit: int | None, estimate_only: bool) -> None:
    jobs, stats = collect_jobs()
    cost = estimate_cost(stats)
    print(json.dumps({"stats": stats, "cost": cost}, indent=2), flush=True)
    if estimate_only:
        return

    env = load_env(ENV)
    key = env.get("GEMINI_API_KEY") or ""
    if not key.startswith("AIza"):
        raise SystemExit("GEMINI_API_KEY missing or does not look like a Google AI key")
    model = os.environ.get("GEMINI_MODEL", "gemini-2.5-flash")

    copied = backfill_out_dir()
    if copied:
        print(f"Backfilled {copied} JSON files from existing checkpoint", flush=True)
    done, totals = load_done()
    pending = [j for j in jobs if job_key(j["id"], j["author"], j["lang"]) not in done]
    if limit is not None:
        pending = pending[:limit]

    state = {
        "model": model,
        "total_jobs": len(jobs),
        "already_done": len(done),
        "this_run": len(pending),
        "ok": totals["ok"],
        "fail": totals["fail"],
        "prompt_tokens": totals["prompt_tokens"],
        "output_tokens": totals["output_tokens"],
        "usd": totals["usd"],
        "started": time.strftime("%Y-%m-%d %H:%M:%S"),
        "last": totals.get("last") or "",
        "out_dir": str(OUT_DIR),
        "progress": str(PROGRESS),
    }
    save_state(state)
    print(
        f"Translating {len(pending)} jobs "
        f"({len(done)} already done / {len(jobs)} total)",
        flush=True,
    )

    for i, job in enumerate(pending, 1):
        max_tok = 8192 if len(job["sanskrit"]) > 1200 else 4096
        label = f"{job['id']} {job['author']} {job['lang']}"
        print(f"[{i}/{len(pending)}] {label} ({len(job['sanskrit'])} chars)", flush=True)
        text = ""
        usage: dict = {}
        finish = ""
        err = None
        for attempt in range(3):
            try:
                text, usage, finish = gemini_translate(
                    key, model, job["prompt"], max_tok
                )
                if looks_truncated(job["sanskrit"], text, finish) and attempt < 2:
                    max_tok = min(max_tok * 2, 16384)
                    print(
                        f"  truncated finish={finish} out={len(text)}; retry max={max_tok}",
                        flush=True,
                    )
                    time.sleep(1)
                    continue
                break
            except Exception as e:
                err = str(e)
                wait = 8 * (attempt + 1)
                if "HTTP 429" in err or "RESOURCE_EXHAUSTED" in err:
                    wait = 30 * (attempt + 1)
                print(f"  FAIL attempt {attempt + 1}: {err[:240]}", flush=True)
                if "API_KEY" in err or "INVALID_ARGUMENT" in err and "key" in err.lower():
                    raise SystemExit("Gemini rejected the API key.")
                time.sleep(wait)
        else:
            persist_result(
                {
                    "id": job["id"],
                    "author": job["author"],
                    "lang": job["lang"],
                    "ok": False,
                    "error": err,
                    "saved_at": time.strftime("%Y-%m-%d %H:%M:%S"),
                }
            )
            state["fail"] += 1
            save_state(state)
            continue

        in_tok = int(usage.get("promptTokenCount") or 0)
        out_tok = int(usage.get("candidatesTokenCount") or 0) + int(
            usage.get("thoughtsTokenCount") or 0
        )
        usd = (in_tok / 1_000_000) * PRICE_IN + (out_tok / 1_000_000) * PRICE_OUT
        result = {
            "id": job["id"],
            "author": job["author"],
            "lang": job["lang"],
            "ok": True,
            "chars": len(text),
            "finish": finish,
            "usage": usage,
            "sanskrit": job["sanskrit"],
            "text": text,
            "saved_at": time.strftime("%Y-%m-%d %H:%M:%S"),
        }
        persist_result(result)
        state["ok"] += 1
        state["prompt_tokens"] += in_tok
        state["output_tokens"] += out_tok
        state["usd"] = round(state["usd"] + usd, 4)
        state["last"] = label
        save_state(state)
        print(
            f"  ok {len(text)} chars tokens in={in_tok} out={out_tok} "
            f"run_usd={state['usd']:.3f}",
            flush=True,
        )
        time.sleep(0.35)

    print(json.dumps(state, indent=2), flush=True)


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--estimate", action="store_true")
    p.add_argument("--limit", type=int, default=None)
    args = p.parse_args()
    run(limit=args.limit, estimate_only=args.estimate)


if __name__ == "__main__":
    main()
