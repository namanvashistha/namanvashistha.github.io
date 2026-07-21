---
title: Devices
description: CYD, cameras, the pi.
section: homelab
---

## ESP32 Cheap Yellow Display

Fork at `~/personal/ESP32-Cheap-Yellow-Display`. Own sketches live separately in
`~/personal/experiments/cyd/`:

- `Leetcode/` — daily question on the display, see
  [CYD LeetCode daily](/docs/homelab/cyd-leetcode/)
- `TouchTest/` — touch calibration, start here when the panel misbehaves

## ESP32 accountability tracker

Separate device from the CYD. Three signals on one display: a large number for
total active days (long-term accountability), colour for today's status, and a
separate weekly indicator.

## ONVIF camera

`~/personal/experiments/camera/` — Python. ONVIF for discovery/control, WebRTC
out via `aiortc` + `MediaRelay`, OpenCV for frames. Not deployed; run locally.

## Home Assistant

Lives in the `dash` repo, at `home.namanvashistha.com`. Two things bite:

- **Pinned to `2026.6`.** `:stable` (2026.7, Python 3.14) deadlocks at boot —
  `ImportExecutor` hangs, 0% CPU, never binds 8123.
- **Bridge networking**, so it can join the `caddy` network. Costs mDNS/DHCP
  discovery — add integrations by IP or cloud. A Zigbee/Z-Wave dongle would need
  `devices:` passthrough and probably host networking.

## Raspberry Pi

`~/personal/pi/backup_2024_07_18/` is a card image dump, not a live checkout.
Boot partition `.dtb`s cover Pi 2B through Zero 2 W.
