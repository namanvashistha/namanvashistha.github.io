---
title: Mac setup gotchas
description: Rosetta Node, and why builds fail on it.
section: dev
---

## Two Homebrews

This machine has both. Intel wins the PATH:

| Prefix | Arch | `node` |
| --- | --- | --- |
| `/usr/local` | x64, under Rosetta | v23.10.0 ← first on PATH |
| `/opt/homebrew` | arm64 (native) | v23.1.0 |

Anything brewed via the `brew` on PATH lands in the Intel prefix and runs
emulated.

## The symptom

```
Error: Cannot find native binding
Cannot find module '@rolldown/binding-darwin-x64'
```

Astro 7 ships Vite 8, which uses rolldown. Bun (arm64) installed the **arm64**
binding; `astro` runs under **x64** Node and looks for the x64 one. Nothing is
wrong with the project — CI is fine, since Linux is x64 throughout.

## Fixes

Per-command, no setup:

```bash
bun --bun run dev     # runs on Bun's own arm64 runtime
```

Permanent — put native Homebrew first in `~/.zshrc`:

```bash
export PATH="/opt/homebrew/bin:$PATH"
```

Then `node -p process.arch` says `arm64` and plain `bun run dev` / `npx` work.
Caveat: this also changes which `brew` you get.
