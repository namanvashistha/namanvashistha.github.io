---
title: How this works
description: How the second brain is wired up.
sidebar:
  order: 1
---

## Where notes live

```
src/content/docs/docs/
  index.md              → /docs/
  meta/how-this-works.md → /docs/meta/how-this-works/
```

The extra `docs/` nesting is deliberate. Starlight serves `src/content/docs/` at
the site root, so nesting one level deeper moves everything under `/docs` and
leaves the rest of the site alone.

## Adding a section

Create a folder. The sidebar is generated from the directory tree, so a new
folder is a new section — no config change.

## Frontmatter

Only `title` is required.

| Field | Purpose |
| --- | --- |
| `title` | Page heading, browser tab, sidebar entry |
| `description` | Page metadata |
| `sidebar.label` | Override the sidebar text |
| `sidebar.order` | Sort within a section, lower first |
| `sidebar.hidden` | Keep out of the sidebar |
| `draft` | Visible in `bun dev`, excluded from builds |

## Visibility

These pages are unlisted: no navbar link, `noindex`, excluded from the sitemap,
and excluded from the site search index. They are reachable by URL — treat them
as public, just not advertised.
