# Gita database pipeline

This document describes how `geeta.db` is built and shipped. Follow this flow to avoid confusion between chapter JSON, bhashya JSON, and the SQLite asset.

## Principles

1. **One canonical source per data type** — do not keep parallel `v4` / `v5` / `v6` chapter JSON trees.
2. **Stable asset name, integer migration** — shipped file is always `geeta.db`. Bump `DB_VERSION` in the app when users must recopy a new build (content or schema). Do not rename the asset on every content fix.
3. **SQLite is compiled, not edited** — never patch `assets/database/*.db` by hand for content changes.
4. **Gemini capture ≠ DB build** — the translation script writes JSON only; `generate_full_db.py` builds the DB.

## Folder layout

```
lib/data/scripts/
  generate_full_db.py          # sole DB builder (run this to produce geeta.db)

  source/
    chapters/                  # canonical chapter source (18 files)
      gita_chapter_1.json
      gita_chapter_2.json
      …
      gita_chapter_18.json
    bhashya/                   # Gemini EN/HI bhashya (one JSON per job)
      2.56__Madhvacharya_Sanskrit__en.json
      …

  archive/chapter-json/        # old v4/v5/v6 + .bak (reference only)
  tools/                       # utilities (batch_gen, cleanup, compare, …)
  legacy/                      # old generate_full_db_v4–v6 (do not use for shipping)
  credentials/                 # local API credential files (gitignored with scripts/)
  data/master_timings.json     # karaoke timing source (separate from shipped timings.json)
  rec/                         # local audio samples for batch_gen

scripts/
  bhashya_translate_gemini.py    # Gemini capture → source/bhashya/ only
  bhashya_gemini_progress.jsonl  # resume checkpoint log
  bhashya_gemini_state.json      # run stats
  prepare_db_asset.py            # iOS-safe journal_mode=DELETE on the DB file

assets/database/
  geeta.db                       # shipped SQLite (built by generate_full_db.py)
  timings.json                   # shipped karaoke timings (separate pipeline)
```

The Flutter app reads **`assets/database/geeta.db`** only. It does not read anything under `lib/data/scripts/`.

## What each source contains

### Chapter JSON (`source/chapters/gita_chapter_*.json`)

Per-verse content used by the generator:

- Mool Shloka, Anvay
- Bhavarth (translations)
- Commentaries (Sanskrit acharyas, AI Insights, etc.)

Edit these files for text fixes (e.g. swapped mool/anvay on 7.13).

### Bhashya JSON (`source/bhashya/*.json`)

Faithful **English and Hindi translations** of Shankara / Ramanuja / Madhva Sanskrit bhashya, produced by Gemini.

Each file looks like:

```json
{
  "id": "2.56",
  "author": "Madhvacharya (Sanskrit)",
  "lang": "en",
  "ok": true,
  "text": "… translation …",
  "sanskrit": "… original Sanskrit …",
  "saved_at": "2026-08-23 15:12:15"
}
```

Skipped at generation time (not stored as bhashya rows):

- Madhva “did not comment on this sloka”
- Copy-forward duplicates (same text as previous verse)
- Lines like `तुल्यत्वार्थ उक्तः पुरस्तात्`

## End-to-end flow

### A. Change chapter / commentary / bhavarth text

1. Edit `lib/data/scripts/source/chapters/gita_chapter_<N>.json`
2. Build DB:
   ```bash
   python3 lib/data/scripts/generate_full_db.py
   python3 scripts/prepare_db_asset.py
   ```
3. Bump `DB_VERSION` in `lib/data/database_helper_mobile.dart` if shipping to devices that already have an older DB.
4. Full restart the app (not hot reload).

### B. Add or refresh Gemini bhashya translations

1. Ensure `.env` has `GEMINI_API_KEY`
2. Capture translations (JSON only):
   ```bash
   python3 scripts/bhashya_translate_gemini.py --estimate   # optional cost check
   python3 scripts/bhashya_translate_gemini.py
   ```
   Writes to **`lib/data/scripts/source/bhashya/`** (not `scripts/bhashya_gemini_out/`).
3. Build DB (same as step A.2–A.4):
   ```bash
   python3 lib/data/scripts/generate_full_db.py
   python3 scripts/prepare_db_asset.py
   ```

### C. Ship to the app

| App constant | Value |
|---|---|
| `DB_FILE_NAME` | `geeta.db` |
| `DB_VERSION` | increment when replacing the bundled DB on user devices (currently `8`) |

On launch, the app copies `assets/database/geeta.db` to documents if `db_version` in SharedPreferences is older than `DB_VERSION`. The filename does not change for content-only updates.

## Script responsibilities

| Script | Reads | Writes | Notes |
|---|---|---|---|
| `scripts/bhashya_translate_gemini.py` | chapter JSON + Gemini API | `source/bhashya/*.json` | **Never touches SQLite** |
| `lib/data/scripts/generate_full_db.py` | `source/chapters/` + `source/bhashya/` | `assets/database/geeta.db` | **Sole DB builder** |
| `scripts/prepare_db_asset.py` | `geeta.db` | same file, in place | Sets `journal_mode=DELETE` for iOS |

## Expected DB contents (v7)

After a full build:

| Commentary | en | hi | sa |
|---|---:|---:|---:|
| AI Insights | 697 | 697 | — |
| Shankaracharya (Sanskrit) | 641 | 641 | 700 |
| Ramanujacharya (Sanskrit) | 621 | 621 | 700 |
| Madhvacharya (Sanskrit) | 366 | 366 | 700 |

**Total commentaries:** 6,750 (includes 3,256 bhashya EN+HI rows).

Typical size: **~49 MB** (includes full FTS search index).

## iOS note

If the DB was written in WAL mode without sidecar files, iOS read-only open can fail. Always run `prepare_db_asset.py` after generating the DB before bundling in the app.

## Do not

- Edit `geeta.db` directly for content — regenerate from source JSON.
- Keep multiple live chapter JSON versions (`v4`, `v5`, `v6`) in `source/chapters/` — use `archive/chapter-json/` for old copies only.
- Run `legacy/generate_full_db_v6.py` for shipping — use `generate_full_db.py` (includes bhashya JSON).
- Expect `scripts/bhashya_gemini_out/` to be used — bhashya output moved to `source/bhashya/`.

## Quick verification

```bash
# Count bhashya JSON files (expect 3256 when complete)
ls lib/data/scripts/source/bhashya/*.json | wc -l

# Check DB commentary totals
sqlite3 assets/database/geeta.db \
  "SELECT language_code, COUNT(*) FROM commentaries GROUP BY 1 ORDER BY 1;"

# Confirm 7.13 mool vs anvay
sqlite3 assets/database/geeta.db \
  "SELECT shloka_text, anvay_text FROM shloka_scripts WHERE shloka_id='7.13' AND script_code='dev';"

# Confirm 3.19 Hindi bhavarth
sqlite3 assets/database/geeta.db \
  "SELECT bhavarth FROM translations WHERE shloka_id='3.19' AND language_code='hi';"
```

## Related app behaviour

- Classical EN/HI bhashya rows use the same `author_name` as Sanskrit (e.g. `Shankaracharya (Sanskrit)`) with `language_code` `en` or `hi`.
- UI groups them via `canonicalAuthorName` and shows **“AI translation of bhashya”** — separate from **AI Insights** modern summary.
