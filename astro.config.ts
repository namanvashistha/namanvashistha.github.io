import mdx from '@astrojs/mdx';
import sitemap from '@astrojs/sitemap';
import { defineConfig } from 'astro/config';
import expressiveCode from 'astro-expressive-code';
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
		rehypePlugins: [
			[rehypeExternalLinks, { target: '_blank', rel: ['noopener', 'noreferrer'] }]
		]
	},
	integrations: [
		expressiveCode({
			themes: [spectreDark],
		}),
		mdx(),
		sitemap(),
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
