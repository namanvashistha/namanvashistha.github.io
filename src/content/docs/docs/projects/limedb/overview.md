---
title: LimeDB
description: Distributed KV store in Go — where things live.
section: projects
subsection: limedb
---

Distributed key-value store in Go. Every node accepts reads and writes; requests
route to the owning node via consistent hashing. Gossip SYN/ACK for membership.
Live at `limedb.namanvashistha.com`.

The README has the architecture diagram and API. This note is the map of the
parts that aren't obvious from it.

## Packages

`internal/` splits by concern, and the names are the design:

| Package | Role |
| --- | --- |
| `ring`, `placement` | consistent hashing, who owns a key |
| `gossiper`, `membership` | cluster state |
| `messenger` | node-to-node transport |
| `store` | the actual KV |
| `node`, `server`, `config` | wiring |
| `telemetry`, `logger` | OTEL + structured logs |

## Beyond the Go code

- `tui/` — Python/Textual client, its own `pyproject.toml`. Separate app.
- `sdk/python/` — client library.
- `proxmox/` — LXC deploy scripts (`limedb_lxc.sh`,
  `deploy_limedb_cluster.sh`) plus Grafana Cloud credential setup. This is the
  bare-metal path, **not** the `deploy.sh` docker path.
- `OTEL_INTEGRATION.md` — telemetry wiring.

## Two deploy paths

`deploy.sh` runs the docker-compose single-node at `limedb.`; the Proxmox
scripts stand up a real multi-node LXC cluster. Don't assume a change to one
covers the other.

Local dev follows [the Go service layout](/docs/dev/go-service-layout/).
