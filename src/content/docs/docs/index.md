---
title: Second Brain
description: Working notes — infrastructure, projects, and things I worked out once and don't want to work out again.
# Without this the browser tab reads "Second Brain | Second Brain", since the
# page title matches the site title.
head:
  - tag: title
    content: Second Brain
---

Things I worked out once and don't want to work out again. Written for me in six
months, who will have forgotten all of it.

Public because notes you can't search aren't notes. If something here saves you
time too, good.

## Sections

| | |
| --- | --- |
| **[infra](/docs/infra/deploy-script/)** | The server. One script deploys six repos behind Caddy — [how it works](/docs/infra/deploy-script/), [what runs where](/docs/infra/domains/) |
| **[homelab](/docs/homelab/devices/)** | [Devices](/docs/homelab/devices/), the [CYD LeetCode display](/docs/homelab/cyd-leetcode/), [media stack](/docs/homelab/media/) |
| **[projects](/docs/projects/limedb/)** | [LimeDB](/docs/projects/limedb/) — distributed KV store in Go. [Chess](/docs/projects/chess/) — bitboard engine + real-time app |
| **[site](/docs/site/architecture/)** | This website: [architecture](/docs/site/architecture/), [CMS](/docs/site/cms/), [build and deploy](/docs/site/deploy/), [resume pipeline](/docs/site/resume-pipeline/) |
| **[dev](/docs/dev/go-service-layout/)** | Reusable technique — [Go service layout](/docs/dev/go-service-layout/), [Mac setup gotchas](/docs/dev/mac-setup/) |
| **[career](/docs/career/prep-system/)** | [Prep and job tooling](/docs/career/prep-system/) |
| **[meta](/docs/meta/how-this-works/)** | [How this works](/docs/meta/how-this-works/) — conventions for writing here |

## Start here

- Something's down → [what runs where](/docs/infra/domains/), then
  [the deploy script](/docs/infra/deploy-script/)
- New machine → [Mac setup gotchas](/docs/dev/mac-setup/)
- New Go service → [the layout everything follows](/docs/dev/go-service-layout/)

Notes are searchable with <kbd>⌘K</kbd>. Rationale lives inline with the thing
it explains, not in a separate pile.
