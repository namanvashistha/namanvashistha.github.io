---
title: How this works
description: How the second brain is wired up.
section: meta
sidebar:
  order: 1
---

## Where notes live

```
src/content/docs/docs/
  index.md                        → /docs/
  meta/how-this-works.md          → /docs/meta/how-this-works/
  projects/limedb/overview.md     → /docs/projects/limedb/overview/
```

**Two levels, no more.** Section, optionally a subsection, then the note.
Starlight will happily nest deeper, but deeper filing is filing for its own
sake — and the CMS only has fields for two.

The extra `docs/` nesting is deliberate. Starlight serves `src/content/docs/` at
the site root, so nesting one level deeper moves everything under `/docs` and
leaves the rest of the site alone.

## Adding a section

The sidebar is generated from the directory tree, so a new folder is a new
section — no config change either way.

- **From an editor** — make a folder, put notes in it.
- **From the CMS** — type a name into the **Section** field, and optionally
  **Subsection**. The note is written to that folder. Reuse an existing name to
  file it alongside; type a new one to start a section.

The CMS writes `section:` into the frontmatter, which Starlight ignores — it
drops frontmatter keys its schema doesn't declare. Notes created in an editor
don't need the field, since their folder already says where they live. Adding it
anyway keeps a note in place if it's later edited from the CMS.

:::caution
Don't edit this page's parent — the `/docs` landing page — from the CMS. It sits
at the collection root with no section, so saving it would file it into a folder
and `/docs/` would stop resolving. Edit it in an editor instead.
:::

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
