import rss from '@astrojs/rss';
import { getCollection } from 'astro:content';
import sanitizeHtml from 'sanitize-html';
import MarkdownIt from 'markdown-it';

const parser = new MarkdownIt();

const renderBody = (body) =>
  sanitizeHtml(parser.render(body || ''), {
    allowedTags: sanitizeHtml.defaults.allowedTags.concat(['img']),
  });

// Microblog notes have no title; derive a short one from the body text.
const noteTitle = (body, max = 70) => {
  const plain = (body || '')
    .replace(/```[\s\S]*?```/g, '')
    .replace(/!\[[^\]]*\]\([^)]*\)/g, '')
    .replace(/[#>*_`~\[\]()!\-]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
  return plain.length > max ? plain.slice(0, max).trim() + '…' : plain || 'Note';
};

export async function GET(context) {
  const [posts, microblog] = await Promise.all([
    getCollection('posts'),
    getCollection('microblog'),
  ]);

  const postItems = posts
    .filter((post) => !post.data.draft)
    .map((post) => ({
      title: post.data.title,
      pubDate: post.data.createdAt,
      link: `/blog/${post.id}/`,
      content: renderBody(post.body),
      categories: post.data.tags.map((tag) => tag.id),
      customData: post.data.image
        ? `<media:content
            type="image/${post.data.image.format == 'jpg' ? 'jpeg' : post.data.image.format}"
            width="${post.data.image.width}"
            height="${post.data.image.height}"
            medium="image"
            url="${context.site + post.data.image.src.replace(/^\//, '')}" />`
        : undefined,
    }));

  const microblogItems = microblog.map((note) => ({
    title: noteTitle(note.body),
    pubDate: note.data.createdAt,
    link: `/microblog/${note.id}/`,
    content: renderBody(note.body),
    categories: (note.data.tags || []).map((tag) => tag.id),
  }));

  const items = [...postItems, ...microblogItems].sort(
    (a, b) => b.pubDate.valueOf() - a.pubDate.valueOf()
  );

  return rss({
    title: 'Naman Vashistha’s Blog',
    description: 'A collection of my thoughts and experiences.',
    site: context.site,
    items,
    customData: `<language>en-us</language>`,
    xmlns: {
      media: 'http://search.yahoo.com/mrss/',
    },
  });
}
