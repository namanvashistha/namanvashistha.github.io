---
title: How this works
description: How the second brain is wired up.
section: meta
---

## Where notes live

```
src/content/docs/docs/
  index.md                        → /docs/
  meta/how-this-works.md          → /docs/meta/how-this-works/
  projects/limedb.md              → /docs/projects/limedb/
  projects/limedb/internals.md    → /docs/projects/limedb/internals/
```

**Two levels, no more.** Section, optionally a subsection, then the note.
Starlight will nest deeper, but deeper filing is filing for its own sake — and
the CMS only has fields for two.

Don't make a subsection folder for a single note. A group wrapping one item
reads as `projects › limedb › LimeDB`, which is noise. Keep it flat until a
project earns a second note, then promote it to a folder.

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

**These pages are public and indexed** — in the navbar, the sitemap, and the ⌘K
search, same as blog posts. Write accordingly: no credentials, no internal
hostnames paired with known weaknesses, nothing that would be a disclosure.

They started out unlisted — `noindex`, out of the sitemap, out of the search
index. That was right while the section was empty, and wrong once it wasn't:
⌘K returned nothing from `/docs`, so notes couldn't be retrieved even by their
author. Being findable is the whole point.

## Recording why

"Why is it like this" goes **inline, in the note about the thing** — a short
`## Why X` section, not a separate decisions section. Context, what was chosen,
what it cost. Write it while the reasoning is fresh; if it's later reversed, say
so in the same place rather than leaving the old answer standing.

A decision only earns a paragraph if it's non-obvious *and* still binding.
Choosing a library nobody will revisit isn't worth writing down.
