# My corner of the internet

This is my personal site — where I write, share what I'm building, and keep my resume. It lives at [namanvashistha.com](https://namanvashistha.com).

There's a blog for longer writing, a microblog for short notes and half-formed thoughts, a projects page for things I've built (LimeDB, chess engines, and the like), and a resume with a proper PDF preview. Everything's searchable with Ctrl+K.

## Running it locally

Built with [Astro](https://astro.build) and TypeScript. I use [Bun](https://bun.sh), but npm works too.

```bash
bun install      # install dependencies
bun run dev      # start the dev server
bun run build    # build for production
bun run preview  # preview the build
```

## How it's laid out

```
public/          static assets — fonts, images, resume.pdf, the CMS admin
src/
  components/    reusable Astro components
  content/       posts, projects, microblog notes (Markdown/MDX) + site data
  layouts/       page shells
  pages/         the actual routes
  styles/        CSS (theming via variables in globals.css)
```

The look is a dark purple/lime theme. Colors live as CSS variables in `src/styles/globals.css` — change `--primary` and the rest follows.

## Writing a post

Drop a `.mdx` file in `src/content/posts/`:

```mdx
---
title: "Your post title"
createdAt: 2026-02-07
tags: [databases, learning]
---

Your words here.
```

Microblog notes are even simpler — a `.md` file in `src/content/microblog/` with just a date and the note. No title needed.

Or skip the files entirely and use the CMS at `/admin` (powered by [Sveltia](https://github.com/sveltia/sveltia-cms)), which writes everything back to the repo for you.

## Deploying my projects

This repo also hosts a small zero-config script that spins up my side projects (`chess`, `foodly`, `hyperbole`, `limedb`) on a fresh server with Docker:

```bash
curl -sSL https://namanvashistha.com/deploy.sh | sudo bash
```

Run it on a schedule with cron (`sudo crontab -e`) if you want daily redeploys:

```cron
0 2 * * * curl -sSL https://namanvashistha.com/deploy.sh | bash
```

## Credits

Built on the [Spectre](https://github.com/louisescher/spectre) theme, then customized and extended. Fork it and make it yours if it's useful.
