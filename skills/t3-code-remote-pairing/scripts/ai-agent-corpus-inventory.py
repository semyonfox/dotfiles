#!/usr/bin/env python3
"""Read-only inventory for local AI-agent corpus stores.

Prints sizes, extension counts, JSONL line counts, and SQLite table counts for
T3, Codex, Hermes, Claude, opencode, Gemini/Antigravity, Cursor, and Copilot.
It never writes to the inspected stores and opens SQLite with mode=ro.
"""
import gzip
import json
import os
import re
import sqlite3
from collections import Counter
from pathlib import Path

HOME = Path.home()
CANDIDATES = [
    HOME / ".t3",
    HOME / ".codex",
    HOME / ".hermes",
    HOME / ".claude",
    HOME / ".local/share/opencode",
    HOME / ".config/opencode",
    HOME / ".gemini",
    HOME / ".cursor",
    HOME / ".config/Cursor",
    HOME / ".copilot",
]


def human(n: int) -> str:
    n = float(n)
    for unit in ["B", "K", "M", "G", "T"]:
        if n < 1024:
            return f"{n:.1f}{unit}"
        n /= 1024
    return f"{n:.1f}P"


def walk_stats(path: Path) -> dict:
    total = files = dirs = 0
    exts = Counter()
    newest = []
    for root, dirnames, filenames in os.walk(path):
        dirs += len(dirnames)
        for filename in filenames:
            p = Path(root) / filename
            try:
                st = p.stat()
            except OSError:
                continue
            files += 1
            total += st.st_size
            exts[p.suffix.lower() or "<none>"] += 1
            newest.append((st.st_mtime, str(p), st.st_size))
    return {
        "bytes": total,
        "human": human(total),
        "files": files,
        "dirs": dirs,
        "top_exts": exts.most_common(10),
        "newest": [(p, human(s)) for _, p, s in sorted(newest, reverse=True)[:8]],
    }


def count_jsonl(path: Path) -> dict:
    opener = gzip.open if path.name.endswith(".gz") else open
    lines = errors = 0
    roles = Counter()
    keys = Counter()
    try:
        with opener(path, "rt", encoding="utf-8", errors="ignore") as f:
            for line in f:
                if not line.strip():
                    continue
                lines += 1
                try:
                    obj = json.loads(line)
                except Exception:
                    errors += 1
                    continue
                if isinstance(obj, dict):
                    keys.update(obj.keys())
                    role = obj.get("role") or obj.get("type") or obj.get("event") or obj.get("event_type")
                    if role:
                        roles[str(role)] += 1
    except Exception as exc:
        return {"error": repr(exc)}
    return {"lines": lines, "json_errors": errors, "roles": roles.most_common(12), "keys": keys.most_common(12)}


def sqlite_counts(path: Path) -> dict:
    out = {"path": str(path)}
    try:
        con = sqlite3.connect(f"file:{path}?mode=ro", uri=True, timeout=10)
        cur = con.cursor()
        out["quick_check"] = cur.execute("PRAGMA quick_check").fetchone()[0]
        tables = []
        for (table,) in cur.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"):
            try:
                count = cur.execute(f'SELECT count(*) FROM "{table}"').fetchone()[0]
            except Exception as exc:
                count = f"ERR {exc!r}"
            tables.append((table, count))
        out["tables"] = tables
        con.close()
    except Exception as exc:
        out["error"] = repr(exc)
    return out


def summarize(path: Path) -> dict:
    result = {"stats": walk_stats(path)}
    jsonls = list(path.rglob("*.jsonl")) + list(path.rglob("*.jsonl.gz"))
    result["jsonl_files"] = len(jsonls)
    total_lines = 0
    roles = Counter()
    for f in jsonls[:50000]:
        c = count_jsonl(f)
        total_lines += c.get("lines", 0)
        roles.update(dict(c.get("roles", [])))
    result["jsonl_lines"] = total_lines
    result["jsonl_roles"] = roles.most_common(12)
    dbs = [p for p in list(path.rglob("*.sqlite")) + list(path.rglob("*.db")) if not p.name.endswith(("-wal", "-shm"))]
    result["sqlite_dbs"] = [sqlite_counts(db) for db in dbs[:30]]
    return result


def main() -> None:
    report = {}
    for path in CANDIDATES:
        if path.exists():
            report[str(path)] = summarize(path)
    report["_aiish_top_level_dirs"] = [
        str(p)
        for p in HOME.iterdir()
        if p.is_dir() and re.search(r"(claude|codex|openai|anthropic|gemini|qwen|aider|cursor|continue|opencode|t3|hermes|copilot|windsurf|roo|cline)", p.name, re.I)
    ]
    print(json.dumps(report, indent=2, default=str))


if __name__ == "__main__":
    main()
