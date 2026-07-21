import { unified } from '@astrojs/markdown-remark';
import mdx from '@astrojs/mdx';
import sitemap from '@astrojs/sitemap';
import starlight from '@astrojs/starlight';
import { defineConfig } from 'astro/config';
import { loadEnv } from 'vite';
import rehypeExternalLinks from 'rehype-external-links';
import spectre, { type GiscusMapping } from './package/src';
import { spectreDark } from './src/ec-theme';

const {
	GISCUS_REPO,
	GISCUS_REPO_ID,
	GISCUS_CATEGORY,
	GISCUS_CATEGORY_ID,
	GISCUS_MAPPING,
	GISCUS_STRICT,
	GISCUS_REACTIONS_ENABLED,
	GISCUS_EMIT_METADATA,
	GISCUS_LANG,
} = loadEnv(process.env.NODE_ENV!, process.cwd(), '');

// https://astro.build/config
const config = defineConfig({
	site: 'https://namanvashistha.com',
	output: 'static',
	build: {
		inlineStylesheets: 'always',
	},
	markdown: {
		processor: unified({
			rehypePlugins: [
				[rehypeExternalLinks, { target: '_blank', rel: ['noopener', 'noreferrer'] }]
			]
		})
	},
	integrations: [
		// Starlight registers Expressive Code itself, so the `astro-expressive-code`
		// integration must NOT also be added here — it registers site-wide, which is
		// why blog posts keep the spectreDark theme.
		starlight({
			title: 'Second Brain',
			// Docs are unlisted: no nav link, out of the sitemap (see filter below),
			// out of the Pagefind index the navbar search reads, and noindex.
			pagefind: false,
			// The site already has src/pages/404.astro; Starlight's would win the
			// route collision and replace it.
			disable404Route: true,
			head: [
				{ tag: 'meta', attrs: { name: 'robots', content: 'noindex, nofollow' } },
			],
			expressiveCode: {
				themes: [spectreDark],
			},
			// Content lives one level deeper (src/content/docs/docs) so that Starlight
			// serves it from /docs instead of the site root. Each folder under it
			// becomes a sidebar group.
			sidebar: [
				{ autogenerate: { directory: 'docs' } },
			],
		}),
		mdx(),
		sitemap({
			filter: (page) => !page.includes('/docs'),
		}),
		spectre({
			name: 'Naman Vashistha',
			openGraph: {
				home: {
					title: 'Naman Vashistha',
					description: 'Software Development Engineer - II',
				},
				blog: {
					title: 'Blog',
					description: 'Technical blog posts and insights.',
				},
				projects: {
					title: 'Projects',
				},
			},
			giscus: GISCUS_REPO ? {
				repository: GISCUS_REPO,
				repositoryId: GISCUS_REPO_ID,
				category: GISCUS_CATEGORY,
				categoryId: GISCUS_CATEGORY_ID,
				mapping: GISCUS_MAPPING as GiscusMapping,
				strict: GISCUS_STRICT === 'true',
				reactionsEnabled: GISCUS_REACTIONS_ENABLED === 'true',
				emitMetadata: GISCUS_EMIT_METADATA === 'true',
				lang: GISCUS_LANG,
			} : false,
		}),
	],
});

export default config;
