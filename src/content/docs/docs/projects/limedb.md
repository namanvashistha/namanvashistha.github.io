---
title: LimeDB
description: Distributed KV store in Go — where things live.
section: projects
---

Distributed key-value store in Go. Every node accepts reads and writes; requests
route to the owning node by consistent hashing. Live at
`limedb.namanvashistha.com`.

The README has the architecture diagram and API. This note is the map of the
parts that aren't obvious from it.

## It was Java first

LimeDB started as Java 21 / Spring Boot with a **coordinator–shard** design:
clients hit one coordinator, which routed by `key.hashCode() % numberOfShards`,
and each shard was its own PostgreSQL database.

The Go rewrite changed the shape, not just the language — every node is now a
peer, routing moved to a consistent hash ring with virtual nodes, and storage
became LimeDB's own rather than PostgreSQL's. Driven by throughput, memory, and
wanting a single binary to deploy.

Both eras are written up: [why build a database](/blog/why-im-building-my-own-distributed-database/)
covers the Java design, [the Go rewrite](/blog/limedb-go-rewrite/) the transition.

:::caution
The rewrite post is **history, not status**. It lists in-memory-only storage and
static peer config as current constraints; both have since been solved. Read the
code, not the post, for present behaviour.
:::

## Packages

`internal/` splits by concern, and the names are the design:

| Package | Role |
| --- | --- |
| `ring`, `placement` | consistent hashing, who owns a key |
| `gossiper`, `membership` | cluster state — heartbeat gossip, node lifecycle |
| `messenger` | node-to-node transport |
| `store` | pluggable storage, see below |
| `node`, `server`, `config` | wiring |
| `telemetry`, `logger` | OTEL traces/metrics/logs, structured logs |

Nodes move through `Bootstrapping → Discovered → Active → Leaving → Left`, with
gossip marking peers `alive`/`dead`. Peers are no longer a static startup list.

## Storage

`store.Backend` is an interface with `memory` and `lsm` implementations, selected
by config.

The LSM backend is written from scratch — `wal.go`, `memtable.go`, `sstable.go`,
`bloom.go`, `compaction.go`, each with tests. This is the most substantial part
of the codebase and the least visible from outside.

Values are `VersionedValue{Value, TimestampMicros, Tombstone}` with
**last-write-wins** resolution: higher timestamp wins; on an exact tie a
tombstone beats a value, otherwise the lexically larger value wins. Deletes write
tombstones rather than removing, so `ListKeys` filters them out.

## Beyond the Go code

- `tui/` — Python/Textual client, its own `pyproject.toml`. Separate app.
- `sdk/python/` — client library.
- `proxmox/` — the bare-metal path, **not** the `deploy.sh` docker path.
- `OTEL_INTEGRATION.md` — telemetry wiring, exports over OTLP/gRPC.

## Two deploy paths

`deploy.sh` runs the docker-compose single node at `limedb.`. The Proxmox scripts
stand up a real multi-node LXC cluster: unprivileged Debian 12 containers, LimeDB
pulled as a release binary into `/usr/local/bin`, managed by a generated systemd
unit. Assumes a `vmbr0` bridge with DHCP and must run as root on the host.
Defaults — container ID, password, `local-lvm` storage — are hardcoded, so change
them before anything resembling production. Written up in
[automating LimeDB on Proxmox](/blog/automating-limedb-lxc/).

Don't assume a change to one path covers the other.

Local dev follows [the Go service layout](/docs/dev/go-service-layout/).
