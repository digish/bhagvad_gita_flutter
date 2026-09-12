#!/usr/bin/env python3
"""Trial: translate real acharya bhashya with Gemini and Sarvam.

Keys come only from the workspace .env (GEMINI_API_KEY, SARVAM_API_KEY).
Placeholder rows (no comment / copy-forward / similar) are skipped.
"""

from __future__ import annotations

import json
import os
import re
import sqlite3
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DB = ROOT / "assets" / "database" / "geeta.db"
ENV = ROOT / ".env"
OUT = ROOT / "scripts" / "bhashya_pilot_results.json"

AUTHORS = [
    "Shankaracharya (Sanskrit)",
    "Ramanujacharya (Sanskrit)",
    "Madhvacharya (Sanskrit)",
]
# Checked: all three have unique, real bhashya here.
PILOT_VERSES = ["2.56", "9.22"]
LANGS = ["en", "hi"]
LANG_NAME = {"en": "English", "hi": "Hindi (Devanagari)"}
SARVAM_TARGET = {"en": "en-IN", "hi": "hi-IN"}

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
- Output only the translation as readable paragraphs. No preamble, no JSON, no title."""


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


def http_json(url: str, payload: dict, headers: dict, timeout: int = 90) -> dict:
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {e.code}: {body[:700]}") from e


def gemini_translate(key: str, model: str, prompt: str) -> str:
    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"{model}:generateContent?key={key}"
    )
    payload = {
        "systemInstruction": {"parts": [{"text": SYSTEM}]},
        "contents": [{"role": "user", "parts": [{"text": prompt}]}],
        "generationConfig": {"temperature": 0.2, "maxOutputTokens": 2048},
    }
    resp = http_json(url, payload, {"Content-Type": "application/json"})
    parts = resp.get("candidates", [{}])[0].get("content", {}).get("parts", [])
    text = "".join(p.get("text", "") for p in parts).strip()
    if not text:
        raise RuntimeError("empty Gemini response")
    return text


def sarvam_chat(key: str, model: str, prompt: str) -> str:
    url = "https://api.sarvam.ai/v1/chat/completions"
    payload = {
        "model": model,
        "temperature": 0.2,
        "max_tokens": 2048,
        "messages": [
            {"role": "system", "content": SYSTEM},
            {"role": "user", "content": prompt},
        ],
    }
    headers = {"Content-Type": "application/json", "api-subscription-key": key}
    resp = http_json(url, payload, headers)
    return resp["choices"][0]["message"]["content"].strip()


def sarvam_translate(key: str, text: str, target: str) -> str:
    url = "https://api.sarvam.ai/translate"
    payload = {
        "input": text[:2000],
        "source_language_code": "sa-IN",
        "target_language_code": target,
        "model": "sarvam-translate:v1",
        "mode": "formal",
    }
    headers = {"Content-Type": "application/json", "api-subscription-key": key}
    resp = http_json(url, payload, headers)
    out = resp.get("translated_text")
    if not out:
        raise RuntimeError(str(resp)[:500])
    return out


def build_prompt(verse: dict, author: str, lang: str, bhashya: str) -> str:
    return f"""Target language: {LANG_NAME[lang]}
Acharya: {author.replace(" (Sanskrit)", "")}
Verse: BG {verse["id"]}
Mula: {verse["shloka"]}
Anvaya (context only): {verse["anvay"]}

Sanskrit bhashya to translate:
{bhashya}"""


def fetch_verses(ids: list[str]) -> dict[str, dict]:
    db = sqlite3.connect(DB)
    db.row_factory = sqlite3.Row
    out: dict[str, dict] = {}
    for sid in ids:
        row = db.execute(
            """
            SELECT s.shloka_text, s.anvay_text
            FROM shloka_scripts s
            WHERE s.shloka_id=? AND s.script_code='dev'
            """,
            (sid,),
        ).fetchone()
        comms = {
            r["author_name"]: r["content"]
            for r in db.execute(
                """
                SELECT author_name, content FROM commentaries
                WHERE shloka_id=? AND language_code='sa'
                """,
                (sid,),
            )
        }
        out[sid] = {
            "id": sid,
            "shloka": row["shloka_text"] if row else "",
            "anvay": row["anvay_text"] if row else "",
            "commentaries": comms,
        }
    return out


def main() -> None:
    env = load_env(ENV)
    gemini_key = env.get("GEMINI_API_KEY") or ""
    sarvam_key = env.get("SARVAM_API_KEY") or ""
    if not gemini_key or not sarvam_key:
        raise SystemExit("GEMINI_API_KEY and SARVAM_API_KEY must both be set in .env")

    gemini_model = os.environ.get("GEMINI_MODEL", "gemini-2.5-flash")
    sarvam_chat_model = os.environ.get("SARVAM_CHAT_MODEL", "sarvam-105b")

    verses = fetch_verses(PILOT_VERSES)
    jobs = []
    skipped = []
    for sid in PILOT_VERSES:
        for author in AUTHORS:
            text = verses[sid]["commentaries"].get(author, "")
            if is_placeholder(text):
                skipped.append({"id": sid, "author": author, "reason": "placeholder"})
                continue
            for lang in LANGS:
                jobs.append((sid, author, lang, text))

    results = {
        "meta": {
            "gemini_model": gemini_model,
            "sarvam_chat_model": sarvam_chat_model,
            "jobs": len(jobs),
            "skipped": skipped,
        },
        "jobs": [],
    }

    print(f"Running {len(jobs)} translations; skipped {len(skipped)} placeholders", flush=True)

    for sid, author, lang, bhashya in jobs:
        prompt = build_prompt(verses[sid], author, lang, bhashya)
        row = {
            "id": sid,
            "author": author,
            "lang": lang,
            "sanskrit": bhashya,
            "gemini": None,
            "sarvam_chat": None,
            "sarvam_translate": None,
            "errors": {},
        }
        print(f"\n--- {sid} {author} {lang} ({len(bhashya)} chars) ---", flush=True)

        try:
            row["gemini"] = gemini_translate(gemini_key, gemini_model, prompt)
            print(f"  Gemini ok ({len(row['gemini'])} chars)", flush=True)
        except Exception as e:
            row["errors"]["gemini"] = str(e)
            print(f"  Gemini FAIL: {e}", flush=True)
            if "API key" in str(e) or "INVALID_ARGUMENT" in str(e):
                results["jobs"].append(row)
                OUT.write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
                raise SystemExit("Stopping: Gemini rejected the API key.")
        time.sleep(0.3)

        try:
            row["sarvam_chat"] = sarvam_chat(sarvam_key, sarvam_chat_model, prompt)
            print(f"  Sarvam chat ok ({len(row['sarvam_chat'])} chars)", flush=True)
        except Exception as e:
            row["errors"]["sarvam_chat"] = str(e)
            print(f"  Sarvam chat FAIL: {e}", flush=True)
            if "invalid_api_key" in str(e) or "authentication" in str(e).lower():
                results["jobs"].append(row)
                OUT.write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
                raise SystemExit("Stopping: Sarvam rejected the API key.")
        time.sleep(0.3)

        try:
            row["sarvam_translate"] = sarvam_translate(
                sarvam_key, bhashya, SARVAM_TARGET[lang]
            )
            print(f"  Sarvam translate ok ({len(row['sarvam_translate'])} chars)", flush=True)
        except Exception as e:
            row["errors"]["sarvam_translate"] = str(e)
            print(f"  Sarvam translate FAIL: {e}", flush=True)
        time.sleep(0.3)

        results["jobs"].append(row)
        OUT.write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"\nWrote {OUT}", flush=True)


if __name__ == "__main__":
    main()
