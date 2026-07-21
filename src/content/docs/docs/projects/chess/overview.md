---
title: Chess
description: Bitboard engine plus a real-time web app.
section: projects
subsection: chess
---

Two things in one repo: a bitboard chess engine, and a real-time two-player web
app around it. Go backend, Postgres for game state, Redis for cache, WebSockets
for live play. Live at `chess.namanvashistha.com`.

## Layout

`app/` is the web side, layered: `router` → `controller` → `service` →
`repository` → `domain`, with `serializer` for the wire format and `engine/`
holding the bitboard logic.

## The engine ships as its own binary

```bash
make uci      # go build -o bin/uci ./cmd/uci
```

`bin/uci` speaks UCI, so it can be pointed at any chess GUI or test harness
independently of the web app. Useful for testing engine strength without the
server in the way.

## Gotchas

- `make test` runs `go test -vet=off` — vet is **deliberately disabled** for a
  pre-existing finding. Re-enabling it will fail until that's fixed.
- `dump.rdb` in the repo root is a stray Redis dump, not config.
- Prod compose brings up redis + postgres + backend + caddy together.

Two blog posts cover the engine design: [bitboards](/blog/chess-engine-bitboards/)
and [the Go rewrite](/blog/chess-engine-go-bitboards/).
