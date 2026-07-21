---
title: Media stack
description: Jackett into Radarr.
section: homelab
---

Radarr at `radarr.namanvashistha.info`. Separate from the `deploy.sh` box.

`~/personal/experiments/jackett_to_radarr/` bulk-registers Jackett indexers into
Radarr, which the UI makes tedious one at a time.

```
jackett_indexes.json   exported indexer list
transfer_script.py     POSTs each to Radarr /api/v3/indexer
```

Run it after re-exporting `jackett_indexes.json` — it doesn't dedupe, so
re-running adds duplicates.

:::caution
`transfer_script.py` has the Radarr API key hardcoded in the URL. Move it to an
env var before this directory ever becomes a git repo.
:::
