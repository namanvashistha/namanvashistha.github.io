# 👋 My Personal Portfolio

Hey! This is my personal portfolio website built with Astro. It's where I share my blog posts, showcase my projects, and host my resume.

## 🚀 What's Inside

- **Blog** - Technical articles and thoughts about development, databases, and whatever I'm learning
- **Projects** - Cool stuff I've built (like LimeDB, chess engines, and more)
- **Resume** - View or download my latest resume with a slick PDF preview
- **Search** - Fast full-text search powered by Pagefind

## 🛠️ Tech Stack

Built with some awesome tools:

- **[Astro](https://astro.build)** - Fast, content-focused framework
- **TypeScript** - Because types make everything better
- **MDX** - Markdown with JSX superpowers for blog posts
- **PDF.js** - Beautiful resume rendering
- **Pagefind** - Lightning-fast static search
- **Tailwind-ish** - Custom CSS with CSS variables for theming

## 🎨 Features

- **Blazing fast** - 100/100 Lighthouse scores
- **Fully responsive** - Looks great on all devices
- **Dark theme** - Easy on the eyes with a customizable color scheme
- **Type-safe** - Full TypeScript throughout
- **SEO optimized** - Auto-generated sitemap, proper meta tags
- **Search** - Find anything with Ctrl+K
- **Dynamic PDF rendering** - Resume page with sharp, responsive PDF display
- **Comments** - Powered by giscus (can toggle off if needed)

## 📦 Getting Started

```bash
# Install dependencies
npm install

# Start dev server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## 🎯 Project Structure

```
/
├── public/          # Static assets (fonts, images, resume.pdf)
├── src/
│   ├── assets/      # Optimized images
│   ├── components/  # Reusable Astro components
│   ├── content/     # Blog posts and projects (MDX)
│   ├── layouts/     # Page layouts
│   ├── pages/       # Routes (blog, projects, resume)
│   ├── scripts/     # Client-side scripts
│   └── styles/      # Global styles
└── package.json
```

## 🎨 Color Customization

The site uses CSS variables for easy theming. Current color scheme is a vibrant purple/lime, but you can change it by editing the `--primary` values in `src/styles/globals.css`:

```css
:root {
  --primary: #8c5cf5;
  --primary-rgb: 140, 92, 245;
  --primary-light: #a277ff;
  --primary-lightest: #c2a8fd;
}
```

## 🌐 Live Site

Check it out at [namanvashistha.com](https://namanvashistha.com)

## 📝 Adding Content

### New Blog Post

Create a new `.mdx` file in `src/content/posts/`:

```mdx
---
title: "Your Post Title"
description: "Brief description"
createdAt: 2026-02-07
tags:
  - tag1
  - tag2
---

Your content here...
```

### New Project

Create a new `.mdx` file in `src/content/projects/`:

```mdx
---
title: "Project Name"
description: "What it does"
date: 2026-02-07
---

Project details...
```

## 🤝 Built With

This site uses the [Spectre](https://github.com/louisescher/spectre) theme as a foundation, customized and enhanced with my own features and styling.

## 📄 License

Feel free to fork and use this as inspiration for your own portfolio!
