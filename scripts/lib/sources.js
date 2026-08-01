/**
 * مصادر التغذية:
 *  - أخبار التقنية (TechCrunch / The Verge / aitnews)
 *  - ترندات جوجل السعودية (RSS رسمي)
 *  - ترندات X/تويتر السعودية (getdaytrends)
 *  - الأخبار السعودية (RSS عربية)
 *  - أحداث العالم (RSS عالمية)
 */
import { XMLParser } from 'fast-xml-parser';
import { log, fetchWithRetry, stripHtml, decodeEntities } from './core.js';

export const TECH_FEEDS = [
  { name: 'TechCrunch', url: 'https://techcrunch.com/feed/' },
  { name: 'The Verge', url: 'https://www.theverge.com/rss/index.xml' },
  { name: 'أخبار التقنية (aitnews)', url: 'https://aitnews.com/feed/' },
];

export const SAUDI_FEEDS = [
  { name: 'الوعي (سعودي)', url: 'https://www.alweeam.com.sa/rss' },
  { name: 'BBC عربي', url: 'https://feeds.bbci.co.uk/arabic/rss.xml' },
];

export const GLOBAL_FEEDS = [
  { name: 'BBC World', url: 'https://feeds.bbci.co.uk/news/world/rss.xml' },
  { name: 'NYT World', url: 'https://rss.nytimes.com/services/xml/rss/nyt/World.xml' },
];

const GOOGLE_TRENDS_URL = 'https://trends.google.com/trending/rss?geo=SA';
const TWITTER_TRENDS_URL = 'https://getdaytrends.com/saudi-arabia/';

const PARSER = () =>
  new XMLParser({
    ignoreAttributes: false,
    attributeNamePrefix: '@_',
    removeNSPrefix: false,
    trimValues: true,
    cdataPropName: '__cdata',
    isArray: (name) => ['item', 'entry', 'media:content', 'media:thumbnail', 'ht:news_item'].includes(name),
  });

function textOf(v) {
  if (v == null) return '';
  if (typeof v === 'string') return v;
  if (typeof v === 'object') {
    if (typeof v.__cdata === 'string') return v.__cdata;
    if (typeof v['#text'] === 'string') return v['#text'];
    return String(v['@_'] ?? '');
  }
  return String(v);
}

function linkOf(raw) {
  const l = raw.link;
  if (typeof l === 'string') return l.trim();
  if (Array.isArray(l)) {
    for (const x of l) {
      if (x && typeof x === 'object' && x['@_href'] && (x['@_rel'] === 'alternate' || !x['@_rel'])) {
        return x['@_href'];
      }
    }
    return null;
  }
  if (l && typeof l === 'object') return l['@_href'] || null;
  return null;
}

function pickValue(obj) {
  if (obj == null) return null;
  if (typeof obj === 'string') return obj;
  if (typeof obj === 'object') return obj['@_url'] || obj.url || obj.href || obj.__cdata || null;
  return null;
}

function extractFirstImg(raw) {
  const content = textOf(raw['content:encoded']) || textOf(raw.description) || textOf(raw.content) || '';
  const match = String(content).match(/<img[^>]+src=["']([^"']+)["']/i);
  return match ? match[1] : null;
}

function extractImage(item) {
  const m = item['media:content']?.[0] ?? item['media:content'];
  const t = item['media:thumbnail']?.[0] ?? item['media:thumbnail'];
  const e = item.enclosure;
  return pickValue(m) || pickValue(t) || (e && pickValue(e)) || extractFirstImg(item);
}

export function normalizeItem(raw, source) {
  const title = decodeEntities(textOf(raw.title)).trim();
  const link = linkOf(raw);
  if (!title || !link) return null;
  return {
    title,
    link,
    description: stripHtml(textOf(raw.description) || textOf(raw.summary) || textOf(raw.content) || '').slice(0, 600),
    pubDate: raw.pubDate || raw.isoDate || raw.published || raw.updated || null,
    source,
    imageUrl: extractImage(raw),
  };
}

export async function fetchRssFeed(feed, maxItems = 10) {
  log(`سحب الخلاصة: ${feed.name}`);
  const res = await fetchWithRetry(feed.url);
  const xml = await res.text();
  const parsed = PARSER().parse(xml);
  const channel = parsed.rss?.channel;
  const atomFeed = parsed.feed;
  const rawItems = channel?.item || atomFeed?.entry || [];
  const items = rawItems
    .map((it) => normalizeItem(it, feed.name))
    .filter((it) => it && it.title && it.link);
  return items.slice(0, maxItems);
}

export async function fetchAggregate(feeds, maxItemsPerFeed = 8, maxTotal = 30) {
  const all = [];
  for (const feed of feeds) {
    try {
      const items = await fetchRssFeed(feed, maxItemsPerFeed);
      log(`${feed.name}: تم جلب ${items.length} عنصراً.`);
      all.push(...items);
    } catch (e) {
      log(`خطأ في المصدر ${feed.name}: ${e.message}`);
    }
  }
  return all.slice(0, maxTotal);
}

function trendExploreUrl(keyword) {
  return `https://trends.google.com/trending/explore?date=now%201-d&geo=SA&q=${encodeURIComponent(keyword)}`;
}

export async function fetchGoogleTrends(maxItems = 12) {
  log('سحب ترندات جوجل السعودية...');
  const res = await fetchWithRetry(GOOGLE_TRENDS_URL, 3, { accept: 'application/rss+xml, application/xml, text/xml, */*' });
  const xml = await res.text();
  const parsed = PARSER().parse(xml);
  const items = parsed?.rss?.channel?.item || [];
  const out = [];
  for (const raw of items) {
    const keyword = decodeEntities(textOf(raw.title)).trim();
    if (!keyword) continue;
    const traffic = textOf(raw['ht:approx_traffic']).trim();
    const newsArr = Array.isArray(raw['ht:news_item']) ? raw['ht:news_item'] : (raw['ht:news_item'] ? [raw['ht:news_item']] : []);
    const first = newsArr[0] || {};
    const storyTitle = textOf(first['ht:news_item_title']).trim();
    const snippet = textOf(first['ht:news_item_snippet']).trim() || storyTitle;
    const storyUrl = textOf(first['ht:news_item_url']).trim();
    const pic = textOf(first['ht:news_item_picture']).trim() || textOf(raw['ht:picture']).trim() || null;
    const targetUrl = storyUrl || trendExploreUrl(keyword);
    out.push({
      title: keyword,
      description: snippet || keyword,
      link: targetUrl,
      url: targetUrl,
      pubDate: raw.pubDate || null,
      source: 'Google Trends السعودية',
      imageUrl: pic || null,
      approxTraffic: traffic || null,
      originalTitle: keyword,
      category: 'ترند',
    });
  }
  log(`ترندات جوجل: ${out.length} ترنداً.`);
  return out.slice(0, maxItems);
}

function isSpamTrend(name) {
  const t = String(name || '');
  if (!t) return true;
  if (/[\u0400-\u04FF\u3040-\u30FF\uAC00-\uD7AF\u4E00-\u9FFF]/.test(t)) return true;
  if (/[0-9]{3,}/.test(t)) return true;
  if (t.length > 45) return true;
  return false;
}

export async function fetchTwitterTrends(maxItems = 12) {
  log('سحب ترندات X السعودية...');
  const res = await fetchWithRetry(TWITTER_TRENDS_URL, 3, {
    ua: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0 Safari/537.36',
    accept: 'text/html',
  });
  const html = await res.text();
  const re = /<td class="main"><a href="[^"]*"[^>]*>(.*?)<\/a>/gi;
  const names = [];
  let m;
  while ((m = re.exec(html)) !== null && names.length < maxItems * 2) {
    const t = decodeEntities(m[1].replace(/<[^>]+>/g, '').replace(/&#39;/g, "'")).trim();
    if (t && !isSpamTrend(t) && !names.includes(t)) names.push(t);
  }
  const cleaned = names.slice(0, maxItems);
  log(`ترندات X: ${cleaned.length} ترنداً.`);
  return cleaned.map((name) => ({
    title: name,
    description: '',
    link: `https://x.com/search?q=${encodeURIComponent(name)}&src=trend_click`,
    url: `https://x.com/search?q=${encodeURIComponent(name)}&src=trend_click`,
    pubDate: new Date().toISOString(),
    source: 'X/تويتر السعودية',
    imageUrl: null,
    approxTraffic: null,
    originalTitle: name,
    category: 'ترند',
  }));
}
