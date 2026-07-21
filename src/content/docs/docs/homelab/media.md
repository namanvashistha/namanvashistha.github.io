---
title: Media stack
description: Jackett into Radarr.
section: homelab
---

Radarr runs on its own host, separate from the `deploy.sh` box.

`~/personal/experiments/jackett_to_radarr/` bulk-registers Jackett indexers into
Radarr, which the UI makes tedious one at a time.

```
jackett_indexes.json   exported indexer list
transfer_script.py     POSTs each to Radarr /api/v3/indexer
```

Run it after re-exporting `jackett_indexes.json` — it doesn't dedupe, so
re-running adds duplicates.

:::caution
Credentials belong in env vars, not in the script. Check before this directory
ever becomes a git repo.
:::
