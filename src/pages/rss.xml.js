import rss from '@astrojs/rss';
import { getCollection } from 'astro:content';

export async function GET(context) {
  const posts = await getCollection('posts');
  return rss({
    title: 'Naman Vashistha’s Blog',
    description: 'A collection of my thoughts and experiences.',
    site: context.site,
    items: posts
      .filter((post) => !post.data.draft)
      .sort((a, b) => b.data.createdAt.valueOf() - a.data.createdAt.valueOf())
      .map((post) => ({
        title: post.data.title,
        pubDate: post.data.createdAt,
        description: post.data.description,
        link: `/blog/${post.id}/`,
      })),
    customData: `<language>en-us</language>`,
  });
}
