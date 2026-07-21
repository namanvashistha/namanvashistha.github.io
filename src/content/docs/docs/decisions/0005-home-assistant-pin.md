---
title: 0005 — Pin Home Assistant to 2026.6
description: Why HA doesn't track :stable.
section: decisions
---

## Context

Home Assistant's `:stable` tag moved to 2026.7, which runs on Python 3.14. On
that release the container deadlocks during boot: `ImportExecutor` hangs at 0%
CPU and never binds 8123. Nothing in the logs points at a cause.

2026.6 is the last minor on Python 3.13.

## Decision

Pin the image to `2026.6` in the `dash` compose file rather than track
`:stable`.

## Consequences

- No HA feature updates and, more importantly, **no security updates** until the
  pin is lifted. This is the real cost — it's an internet-facing service.
- The pin is easy to forget. It's recorded here and in `dash`'s README.
- Lift once HA's Python 3.14 boot bug is fixed, and verify by watching for the
  8123 bind rather than assuming a clean start.

Related: HA also runs on bridge networking so it can join the `caddy` network,
which costs mDNS/DHCP discovery. Separate trade-off, same service — see
[devices](/docs/homelab/devices/).
