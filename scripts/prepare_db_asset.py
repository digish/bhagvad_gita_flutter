#!/usr/bin/env python3
"""Prepare a SQLite DB for Flutter asset bundling.

Merges WAL sidecars into the main file and switches journal_mode to DELETE so
iOS can open the copied DB read-only without -wal/-shm sidecars in the bundle.
"""

from __future__ import annotations

import argparse
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT = ROOT / "assets" / "database" / "geeta_v7.db"


def prepare(path: Path) -> None:
    if not path.exists():
        raise SystemExit(f"Missing {path}")
    conn = sqlite3.connect(path)
    try:
        conn.execute("PRAGMA wal_checkpoint(TRUNCATE)")
        mode = conn.execute("PRAGMA journal_mode=DELETE").fetchone()[0]
        ok = conn.execute("PRAGMA integrity_check").fetchone()[0]
        conn.commit()
    finally:
        conn.close()
    for suffix in ("-wal", "-shm"):
        sidecar = path.with_name(path.name + suffix)
        if sidecar.exists():
            sidecar.unlink()
    if mode.lower() != "delete":
        raise SystemExit(f"journal_mode is {mode!r}, expected delete")
    if ok != "ok":
        raise SystemExit(f"integrity_check failed: {ok}")
    rows = sqlite3.connect(path).execute(
        """
        SELECT COUNT(*) FROM commentaries
        WHERE language_code IN ('en','hi')
          AND author_name LIKE '%acharya%'
        """
    ).fetchone()[0]
    print(f"Prepared {path} journal_mode={mode} integrity={ok} en/hi_bhashya={rows}")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("db", nargs="?", default=str(DEFAULT))
    args = p.parse_args()
    prepare(Path(args.db))


if __name__ == "__main__":
    main()
