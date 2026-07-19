#!/usr/bin/env python3
"""Search the team knowledge base (sources/) with multiple keywords.

Usage:
    python docs_search.py KEYWORD [KEYWORD ...]

Resolves the repo root from TEAM_WORKFLOWS_DIR, falling back to this
script's real location (works through junctions/symlinks).
Standard library only - no external dependencies.
"""
import os
import sys
from pathlib import Path

TOP_N = 15
PREVIEW_PER_FILE = 2
PREVIEW_WIDTH = 100


def repo_root() -> Path:
    env = os.environ.get("TEAM_WORKFLOWS_DIR")
    if env:
        p = Path(env)
        if (p / "sources").is_dir():
            return p
    # <repo>/skills/docs-grep/scripts/docs_search.py -> <repo>
    here = Path(__file__).resolve()
    return here.parents[3]


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    keywords = [k for k in sys.argv[1:] if k.strip()]
    if not keywords:
        print("usage: docs_search.py KEYWORD [KEYWORD ...]")
        return 1

    root = repo_root()
    src = root / "sources"
    if not src.is_dir():
        print(f"[error] sources/ not found: {src}")
        print("Set TEAM_WORKFLOWS_DIR to the repo root, or run /team-setup.")
        return 1

    lowered = [k.lower() for k in keywords]
    results = []
    for path in sorted(src.rglob("*.md")):
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        hit_kinds = set()
        total_hits = 0
        previews = []
        for lineno, line in enumerate(text.splitlines(), 1):
            low = line.lower()
            matched = [k for k in lowered if k in low]
            if matched:
                hit_kinds.update(matched)
                total_hits += len(matched)
                if len(previews) < PREVIEW_PER_FILE:
                    previews.append(f"    L{lineno}: {line.strip()[:PREVIEW_WIDTH]}")
        if hit_kinds:
            results.append((len(hit_kinds), total_hits, path, previews))

    if not results:
        print("no matches. try different keywords.")
        return 0

    results.sort(key=lambda r: (-r[0], -r[1], str(r[2])))
    print(f"keywords: {', '.join(keywords)}")
    print(f"top {min(TOP_N, len(results))} of {len(results)} matched files\n")
    for kinds, hits, path, previews in results[:TOP_N]:
        rel = path.relative_to(root)
        print(f"[{kinds}/{len(keywords)} keywords, {hits} hits] {rel}")
        for pv in previews:
            print(pv)
    return 0


if __name__ == "__main__":
    sys.exit(main())
