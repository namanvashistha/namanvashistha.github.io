---
title: Go service layout
description: The compose + Makefile convention shared across services.
section: dev
---

`limedb`, `chess` and the other deployable Go services all follow the same
shape. Copy it when starting a new one.

```
docker-compose.yml       prod — what deploy.sh runs
docker-compose.dev.yml   dev — hot reload, source mounted
Dockerfile / .dev        one each
Makefile                 dev / dev-bg / dev-logs / dev-down / prod / prod-down
cmd/ internal/ web/      go layout
```

## Why two compose files

`deploy.sh` on the server only ever runs plain `docker compose up` against
`docker-compose.yml`. Dev concerns — bind mounts, hot reload, exposed ports —
stay in `.dev.yml` so they can't leak into prod by accident.

`limedb` splits a third, `docker-compose.dev.ports.yml`, for when you want the
cluster's ports on the host.

## Logs

`limedb` emits structured JSON and pipes through
[humanlog](https://github.com/humanlogio/humanlog) to read it:

```bash
make install-tools     # go install humanlog
make dev               # up --build, piped through humanlog
make dev-logs          # tail an already-running cluster
```

## Prod labels

Anything that should get a subdomain joins the `caddy` network and carries
`caddy: http://<name>.namanvashistha.com` + `caddy.reverse_proxy: "{{upstreams PORT}}"`.
See [the deploy script](/docs/infra/deploy-script/).
