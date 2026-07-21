---
title: CMS
description: Sveltia at /admin, and its limits.
section: site
---

Sveltia CMS at `/admin`. GitHub backend, commits straight to `main`, which
triggers the normal deploy. Installed as a PWA, so it works from a phone.

Config: `public/admin/config.yml`. Page: `src/pages/admin.astro` (loads Sveltia
from unpkg, `noindex`).

## Auth

Cloudflare Worker at `github-oauth.namanvashistha15.workers.dev`, source in
`functions/oauth.js`. Two routes: `/api/auth` redirects to GitHub, `/api/callback`
exchanges the code. Scope is `public_repo,user:email`.

## Images

One global rule, because Sveltia ignores per-collection `public_folder` for the
markdown *body* widget: body images go to `public/uploads` and are referenced as
`/uploads/<file>`. Cover images are the exception — those use the collection's
`public_folder` (`../assets`) so Astro can optimise them.

## Limits worth remembering

- **No nested collections.** Decap's `nested` option isn't implemented (due in
  Sveltia 1.0). Subfolders are driven by a `path` template instead — that's how
  the docs collection's Section field works.
- Setting `path` is also what makes Sveltia *list* entries inside subfolders.
  Without it the collection only reads its root.
- Editing a note relocates it to match its `path`. See the caution in
  [How this works](/docs/meta/how-this-works/).
