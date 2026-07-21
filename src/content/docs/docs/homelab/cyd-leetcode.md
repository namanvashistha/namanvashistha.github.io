---
title: CYD LeetCode daily
description: Daily question on the Cheap Yellow Display.
section: homelab
---

`~/personal/experiments/cyd/Leetcode/Leetcode.ino`. Pulls LeetCode's daily
question and scrolls it on the CYD.

## How it works

- **Fetch**: `POST https://leetcode.com/graphql`, query
  `questionOfToday { activeDailyCodingChallengeQuestion }` → title, frontend id,
  difficulty, HTML body. No auth needed.
- **Sanitize**: `sanitizeHtml()` strips tags; the body arrives as HTML.
- **Render**: TFT_eSPI, `setRotation(0)` (portrait). Text is pre-wrapped into
  `wrappedLines`, drawn a window at a time.
- **Scroll**: auto-advances one line per second, wraps at the end.
- **Touch**: any touch toggles auto-scroll on/off. 300 ms debounce, no
  coordinate regions — the whole screen is the button.
- **Refresh**: hourly (`fetchInterval = 3600000`).

## Wiring

Touch is XPT2046 on its own SPI bus, separate from the display:
IRQ 36, MOSI 32, MISO 39, CLK 25, CS 33. Display pins come from TFT_eSPI's
config, not this sketch — a wrong `User_Setup.h` is the usual cause of a white
or mirrored screen. `TouchTest/` in the same folder isolates the touch side.

## Gotchas

- WiFi is a hardcoded array of SSID/password structs, tried in order with a
  10 s timeout each. Adding a network means reflashing.
- `DynamicJsonDocument(8192)` — a long question body will silently truncate.
  Failures show as `JSON Error` / `API Error` on screen; check serial for more.
- `leetcode.txt` alongside is an **older copy** of the sketch, not a data file.
  The two have diverged; `.ino` is the real one.

:::caution
The sketch has real WiFi passwords in plaintext. Keep this folder out of git, or
move credentials into a `secrets.h` that's gitignored, before publishing it.
:::
