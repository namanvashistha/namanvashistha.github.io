---
title: What runs where
description: Subdomain map.
section: infra
---

All on one box behind `caddy-docker-proxy`, except the site itself.

| Host | Repo | Port |
| --- | --- | --- |
| `namanvashistha.com` | this repo | GitHub Pages, not the server |
| `chess.` | chess | 9000 |
| `foodly.` | foodly | 80 |
| `hyperbole.` | hyperbole | 8080 |
| `limedb.` | limedb | 3000 |
| `home.` | dash | 8123 — Home Assistant |
| `dash.` | dash | 8080 — Glance |

`text-to-image-bot` is deployed by the same script but has no HTTP ingress —
it's a Telegram long-poll bot, so no subdomain.


## Notes

- `home.` is internet-facing and controls the house. Strong password + MFA;
  Cloudflare Access or a VPN in front would be better.
- The apex is the only thing not on the server — pushing to `main` deploys it
  via Actions, everything else needs `deploy.sh` run on the box.
