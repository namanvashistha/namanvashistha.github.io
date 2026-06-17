# DESIGN.md

The system is centralized in `src/styles/globals.css :root` as tokens. Everything else references tokens; never hardcode hex.

## Color strategy
Restrained-but-confident. Tinted-violet neutrals + one accent (violet) used decisively in signature moments (active nav, featured post, links, accents, focus). All neutrals are tinted toward the brand hue (≈293), never pure `#000`/`#fff`. Colors are authored in OKLCH.

| Token | Value | Use |
|---|---|---|
| `--bg` | `oklch(0.17 0.012 293)` | page |
| `--surface-1` | `oklch(0.215 0.014 293)` | cards |
| `--surface-2` | `oklch(0.265 0.016 293)` | chips, inputs, inline code |
| `--surface-3` | `oklch(0.32 0.018 293)` | hover raised |
| `--border` | `oklch(0.31 0.014 293)` | hairlines |
| `--border-strong` | `oklch(0.42 0.016 293)` | emphasis dividers |
| `--text` | `oklch(0.93 0.008 293)` | primary |
| `--text-muted` | `oklch(0.75 0.012 293)` | secondary |
| `--text-subtle` | `oklch(0.60 0.012 293)` | meta |
| `--primary` | `oklch(0.65 0.20 293)` | accent |
| `--primary-light` | `oklch(0.76 0.15 293)` | links |
| `--primary-lightest` | `oklch(0.86 0.09 293)` | inline code, link hover |
| `--primary-rgb` | `139, 92, 246` | rgba glows |

## Typography
- **Display (headings):** `Bricolage Grotesque Variable` — a humanist grotesque with optical sizing, deliberately not a reflex pick. Weight 600–700, tight tracking.
- **Body / UI:** `Geist`.
- **Code only:** `Geist Mono`. Mono never used as decorative "tech" shorthand.
- Fluid modular scale via `clamp()`, ratio ≥1.25. Dark-mode line-height bumped (1.6 body, 1.15 display).

## Shape & elevation
- Radius: `--radius-sm 6px`, `--radius 12px`, `--radius-lg 16px`.
- Elevation: `--shadow-sm` (rest), `--shadow` (hover lift), `--shadow-accent` (focused accent glow).

## Motion
- Curve: `--ease-out-expo cubic-bezier(0.16, 1, 0.3, 1)`. No bounce/elastic.
- One orchestrated page-load: cards fade-up with a short stagger. Never animate layout props (transform/opacity only).
- All motion gated by `prefers-reduced-motion`.

## Signature moments
- Page-load staggered card reveal.
- Nav: animated sliding underline for hover/active (no block fill).
- Blog list: the newest post is featured (accent ring + label).
- Card hover: lift + accent border + soft accent glow at the top edge.
- Links: animated underline grow (not instant).

## Bans honored
No side-stripe accent borders, no gradient text, no glassmorphism-by-default, no hero-metric template, no identical card grids, no em dashes in copy.
