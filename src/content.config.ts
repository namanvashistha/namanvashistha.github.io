import { defineCollection, reference, z } from 'astro:content';
import type { icons as lucideIcons } from '@iconify-json/lucide/icons.json';
import type { icons as simpleIcons } from '@iconify-json/simple-icons/icons.json';
import { glob } from 'astro/loaders';
import { promises as fs } from 'node:fs';

// Helper loader to read a specific key from a JSON file
const jsonListLoader = (path: string, key: string) => {
	return {
		name: `json-list-${key}`,
		load: async ({ store, logger, parseData }: any) => {
			logger.info(`Loading ${key} from ${path}`);
			try {
				const content = await fs.readFile(path, 'utf-8');
				const data = JSON.parse(content);
				const items = data[key];
				
				if (!Array.isArray(items)) {
					logger.warn(`Expected array at key '${key}' in ${path}, got ${typeof items}`);
					return;
				}

				for (const item of items) {
					// Ensure ID is string for store
					const id = String(item.id);
					// Validate/Parse data if needed, or just set it
					// content layer store.set expects { id, data }
					store.set({ id, data: item });
				}
			} catch (e: any) {
				logger.error(`Failed to load ${path}: ${e.message}`);
			}
		}
	};
};

const other = defineCollection({
	loader: glob({ base: 'src/content/other', pattern: '**/*.{md,mdx}' }),
});

const about = defineCollection({
       loader: glob({ base: 'src/content/about', pattern: '*.mdx' }),
       schema: z.object({
	       title: z.string().optional(),
       }),
});

const lucideIconSchema = z.object({
	type: z.literal('lucide'),
	name: z.custom<keyof typeof lucideIcons>(),
});

const simpleIconSchema = z.object({
	type: z.literal('simple-icons'),
	name: z.custom<keyof typeof simpleIcons>(),
});

const quickInfo = defineCollection({
	loader: jsonListLoader('src/content/info.json', 'info'),
	schema: z.object({
		id: z.number(),
		icon: z.union([lucideIconSchema, simpleIconSchema]),
		text: z.string(),
	}),
});

const socials = defineCollection({
	loader: jsonListLoader('src/content/socials.json', 'socials'),
	schema: z.object({
		id: z.number(),
		icon: z.union([lucideIconSchema, simpleIconSchema]),
		text: z.string(),
		link: z.string().url(),
	}),
});

const workExperience = defineCollection({
	loader: jsonListLoader('src/content/work.json', 'work'),
	schema: z.object({
		id: z.number(),
		title: z.string(),
		company: z.string(),
		duration: z.string(),
		description: z.string(),
	}),
});

const tags = defineCollection({
	loader: jsonListLoader('src/content/tags.json', 'tags'),
	schema: z.object({
		id: z.string(),
	}),
});

const posts = defineCollection({
	loader: glob({ base: 'src/content/posts', pattern: '**/*.{md,mdx}' }),
	schema: ({ image }) =>
		z.object({
			title: z.string(),
			createdAt: z.coerce.date(),
			updatedAt: z.coerce.date().optional(),
			description: z.string(),
			tags: z.array(reference('tags')),
			draft: z.boolean().optional().default(false),
			image: image(),
		}),
});

const projects = defineCollection({
	loader: glob({ base: 'src/content/projects', pattern: '**/*.{md,mdx}' }),
	schema: ({ image }) =>
		z.object({
			title: z.string(),
			description: z.string(),
			date: z.coerce.date(),
			image: image(),
			link: z.string().url().optional(),
			info: z.array(
				z.object({
					text: z.string(),
					icon: z.union([lucideIconSchema, simpleIconSchema]),
					link: z.string().url().optional(),
				})
			),
		}),
});

export const collections = { tags, posts, projects, other, about, quickInfo, socials, workExperience };
