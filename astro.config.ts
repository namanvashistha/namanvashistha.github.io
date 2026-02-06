import mdx from '@astrojs/mdx';
import node from '@astrojs/node';
import sitemap from '@astrojs/sitemap';
import { defineConfig } from 'astro/config';
import expressiveCode from 'astro-expressive-code';
import { loadEnv } from 'vite';
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
	site: 'https://namanvashistha.github.io',
	output: 'static',
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
		}),
	],
	adapter: node({
		mode: 'standalone',
	}),
});

export default config;
