---
title: 0004 — Notes are public and indexed
description: Reversing the original unlisted decision.
section: decisions
---

## Context

`/docs` shipped deliberately unlisted: `noindex`, excluded from the sitemap, no
nav link, and excluded from the Pagefind index the navbar search reads. That was
right while the section was empty.

At 16 notes it was actively counterproductive. ⌘K on this site returned nothing
from `/docs`, so the notes couldn't be retrieved even by their author. The
argument for writing things down at all — that a search six months later lands
you on your own answer — was structurally impossible.

## Decision

Make `/docs` fully public: drop `noindex`, restore it to the sitemap, add a
**Notes** nav link, and return the Pagefind glob to the whole site.

## Consequences

- Anything written here is public. Nothing goes in that shouldn't be — no
  credentials, no "service X has weak auth", no internal hostnames paired with
  known weaknesses. Three notes were edited for exactly this before the switch.
- The old Pagefind glob was an allowlist of public sections, which failed safe.
  Indexing everything means a future private section would need explicit
  exclusion, which fails open. Worth remembering if one is ever added.
- Notes now compete with blog posts in site search results.

**Revisit if** a genuinely private category of note appears. The answer then is a
separate mechanism, not re-hiding the whole section.
