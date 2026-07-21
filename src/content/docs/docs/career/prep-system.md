---
title: Prep and job tooling
description: Where the interview prep and job-search pieces live.
section: career
---

Five separate repos, one workflow. This note is the map; each has its own README.

| Repo | What |
| --- | --- |
| `dsa/` | NeetCode 150 as markdown — 18 topic folders, one file per problem, `README.md` is the master index |
| `stride/` | Chrome extension, replaces new tab with a prep dashboard (category → subcategory → links) |
| `lumen/` | Chrome MV3 extension, exports LinkedIn connections to Telegram |
| `jobs-scrape-to-notion/` | Scrapes listings into Notion |
| `resume/` | Standalone LaTeX resume repo — separate from the one in the site |

## Two resume pipelines

Don't confuse them:

- `~/personal/resume/` — its own repo, builds on push to main.
- `namanvashistha.github.io/resume/` — the one that feeds the site and commits
  PDFs to `public/`. See [resume pipeline](/docs/site/resume-pipeline/).

They share a lineage but have drifted. The site one is the live path.

## Notes

- `dsa/` is already a complete knowledge base — link to it, don't copy problems
  in here.
- `career-ops/` in `~/personal` is a **clone of someone else's** multi-agent job
  search system (`santifer/career-ops`), not yours.
