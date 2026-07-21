---
title: Site architecture
description: What this site is built from.
section: site
---

Astro 7 static site, custom domain `namanvashistha.com`, hosted on GitHub Pages.

## Pieces

| Thing | Where |
| --- | --- |
| Theme | `package/src/` — local integration, exposes the `spectre:globals` virtual module (name, themeColor, OG defaults, giscus config) |
| Layout | `src/layouts/Layout.astro` — one layout, `left`/`right` slots via `LayoutGrid` |
| Search | Pagefind, indexed in `postbuild`, UI is hand-rolled in `Navbar.astro` (⌘K) |
| Comments | giscus, config injected from workflow env |
| Analytics | Umami, plus hits.sh view badges on blog posts |
| Docs | Starlight, at `/docs` — the one part with its own layout |

## Collections

`src/content.config.ts`. Markdown ones use `glob()`; the JSON ones use a
hand-written `jsonListLoader` that reads a single key out of a file.

- `posts`, `projects`, `microblog`, `about`, `docs` — files
- `tags`, `socials`, `workExperience`, `quickInfo` — JSON, one key each
- `tags` is referenced by the others via `reference('tags')`

## Gotchas

- `public/_headers` sets `X-Robots-Tag: noindex` on `/*`. That's Cloudflare/Netlify
  syntax — **GitHub Pages ignores it entirely**, so it does nothing. Leftover.
- `work.json` is `{"work": []}`, so the build warns that `workExperience` is
  empty on every run. Expected.
- `src/content/other/` doesn't exist but is still declared as a collection —
  second warning on every build.
