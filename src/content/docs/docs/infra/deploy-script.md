---
title: The deploy script
description: One script, six repos, one server.
section: infra
---

`public/deploy.sh` in this repo is the spine. Run it **on the server**. It clones
or pulls each repo in `REPOS`, runs `docker compose up -d --build`, then starts
`caddy-docker-proxy` in front of everything.

Services find Caddy through the shared `caddy` docker network, and route
themselves with labels in their own compose file — no central Caddyfile.

## Add a service

1. One line in `REPOS`: `"name|https://github.com/namanvashistha/name.git"`
2. Its compose file joins the `caddy` network and sets
   `caddy: http://name.namanvashistha.com` + `caddy.reverse_proxy: "{{upstreams PORT}}"`
3. Re-run `deploy.sh`

## Why labels instead of a Caddyfile

Routing lives in each service's own compose file, not in a central config. A repo
carries its own hostname and port, so adding a service touches one line here and
nothing else — and there's no central file to drift out of sync with reality.

The cost: routing is only discoverable by reading every compose file, which is
why [what runs where](/docs/infra/domains/) exists as a written map.

## Two TLS modes

Auto-detected by comparing the public IP to the first repo's DNS record.

- **Match → EC2**: Caddy provisions Let's Encrypt itself.
- **No match → behind Cloudflare**: `auto_https=off`, Caddy serves plain HTTP.
  The `http://` scheme on labels is **required** in this mode.

## Where things are

```
~/namanvashistha/            # BASE_DIR, one dir per repo
~/namanvashistha/deploy.log  # all output
~/namanvashistha/.deploy.lock.dir  # mkdir-based lock, stale one blocks reruns
```

Containers are set to `restart unless-stopped` after each up. A failed repo is
counted and reported, but doesn't stop the rest.
