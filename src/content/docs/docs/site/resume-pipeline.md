---
title: Resume pipeline
description: JSON to LaTeX to committed PDF.
section: site
---

JSON profile → Jinja2 → LaTeX → PDF. Python, run with `uv`.

```
resume/profiles/*.json   source of truth (editable in the CMS)
resume/template.tex.j2   layout
resume/generate.py       renders, compiles, copies
resume/output/           .tex/.aux/.log — gitignored
public/resume*.pdf       committed output
```

Run one: `cd resume && uv run generate.py profiles/base.json`

## In CI

Only runs when `git diff HEAD~1` touches `resume/` — otherwise texlive and uv
are never even installed, which is most of what keeps the build fast. Installs
`texlive-latex-base/extra` + fonts, generates every profile, commits the PDFs
back to `public/`.

## Notes

- `generate.py` escapes LaTeX specials character-by-character to avoid
  double-escaping — worth remembering before "simplifying" it to a regex.
- PDFs are committed, not built on demand. A profile edit via the CMS therefore
  costs two pipeline runs: yours, then the bot's.
- Profiles sort by filename prefix (`1_edit.json`), which is how ordering in the
  UI is controlled.
