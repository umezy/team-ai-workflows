---
name: docs-grep
description: Search the team knowledge base (sources/) with multiple keywords, rank files by relevance, and answer the user's question from the top hits. Use on requests like "search the docs", "look up ...", or "docs-grep".
---

# Knowledge base search

## Arguments

`$ARGUMENTS` -> the user's question or topic to research

## Workflow

### Step 1. Generate keywords

Derive 4–8 search keywords from the question. Include synonyms, abbreviations, and both English and native-language variants where relevant.

### Step 2. Run the search

```bash
python "$HOME/.claude/skills/docs-grep/scripts/docs_search.py" <keyword1> <keyword2> ...
```

- The script resolves `sources/` from the `TEAM_WORKFLOWS_DIR` environment variable, falling back to its own real location (works through junctions/symlinks)
- Ranking: number of distinct keywords matched first, then total hit count

### Step 3. Answer

Read the top-ranked files and answer the question. Cite the relative paths of the files you used. If the hits look weak, adjust the keywords and repeat Step 2.
