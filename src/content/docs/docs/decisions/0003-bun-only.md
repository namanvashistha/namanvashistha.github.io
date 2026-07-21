---
title: 0003 — Bun is the only package manager
description: Why package-lock.json was deleted.
section: decisions
---

## Context

The repo carried both `bun.lock` and `package-lock.json`. Only `bun.lock` was
maintained — `packageManager` names Bun, and CI runs `bun install`.
`package-lock.json` hadn't been regenerated in a month and still pinned
`@astrojs/mdx@6`, so after the Astro 7 upgrade `npm i` failed to resolve.

## Decision

Delete `package-lock.json`. Bun is the only supported package manager.

## Consequences

- `npm i` is no longer a supported command in this repo. Use `bun install`.
- One lockfile, so no possibility of the two disagreeing about the tree.
- If npm support is ever wanted back, the lockfile must be regenerated *and*
  kept in sync deliberately — two lockfiles is a maintenance commitment, not a
  free convenience.
