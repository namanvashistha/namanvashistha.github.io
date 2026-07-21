---
title: Build and deploy
description: How a push becomes a live site.
section: site
---

`.github/workflows/deploy.yml`, on push to `main`. Bun 1.3.8 → `bun install` →
`bun run build` → upload `dist/` → `actions/deploy-pages`.

## Two loops guard against themselves

- The job **skips commits authored by `github-actions[bot]`**, because the
  resume step pushes its own commit.
- That commit is also tagged `[skip ci]`.

Both exist because the workflow writes back to the repo it builds from — hence
`contents: write` and `fetch-depth: 2`.

## Secrets aren't secret

giscus IDs and the Umami site ID are plain `env:` values in the workflow, not
repository secrets. They're public identifiers, so that's fine — just don't
assume the workflow is a safe place for real secrets by analogy.

## Package manager

Bun, not npm. `packageManager: bun@1.3.8`, CI runs `bun install`, `bun.lock` is
the live lockfile. `package-lock.json` was deleted 2026-07-21 — it had drifted
months out of date and made `npm i` fail to resolve.

## Commands

```bash
bun install
bun run dev      # see env/mac-setup if this fails on rolldown
bun run build    # runs pagefind in postbuild
bun run lint     # currently fails repo-wide on pre-existing formatting drift
```
