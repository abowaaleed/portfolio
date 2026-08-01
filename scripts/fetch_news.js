/**
 * جلب أخبار التقنية اليومية من خلاصات RSS وتلخيصها وترجمتها إلى العربية
 * عبر Google Gemini، ثم تخزينها في Firebase Firestore (مجموعة news).
 *
 * المتغيرات البيئية المطلوبة:
 *   GEMINI_API_KEY            مفتاح Google Gemini API (إلزامي للتلخيص)
 *   FIREBASE_SERVICE_ACCOUNT  محتوى JSON لمفتاح الخدمة (إلزامي للحفظ)
 *   GEMINI_MODEL              النموذج المستخدم (الافتراضي gemini-1.5-flash)
 *   MAX_ITEMS_PER_FEED        عدد الأخبار القصوى لكل مصدر (الافتراضي 5)
 *   FETCH_IMAGES              جلب صورة الخبر وتخزينها base64 (الافتراضي true)
 *   DRY_RUN                   true = تجربة بدون الحفظ الفعلي (الافتراضي false)
 */
import admin from 'firebase-admin';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { XMLParser } from 'fast-xml-parser';
import { pathToFileURL } from 'node:url';

const {
  GEMINI_API_KEY,
  FIREBASE_SERVICE_ACCOUNT,
  GEMINI_MODEL = 'gemini-2.0-flash',
  MAX_ITEMS_PER_FEED = '5',
  FETCH_IMAGES = 'true',
  DRY_RUN = 'false',
} = process.env;

const maxItemsPerFeed = Math.max(1, parseInt(MAX_ITEMS_PER_FEED, 10) || 5);
const fetchImages = FETCH_IMAGES === 'true';
const dryRun = DRY_RUN === 'true';

const FEEDS = [
  { name: 'TechCrunch', url: 'https://techcrunch.com/feed/' },
  { name: 'The Verge', url: 'https://www.theverge.com/rss/index.xml' },
  { name: 'أخبار التقنية (aitnews)', url: 'https://aitnews.com/feed/' },
];

const CATEGORIES = ['أجهزة', 'ذكاء اصطناعي', 'استحواذات', 'تقنية عامة'];

let db = null;

function log(...args) {
  console.log(new Date().toISOString(), ...args);
}

async function fetchWithRetry(url, attempts = 3) {
  let lastErr;
  for (let i = 1; i <= attempts; i++) {
    try {
      const res = await fetch(url, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; PortfolioNewsFetcher/1.0; +https://github.com/abowaaleed/portfolio)',
          Accept: 'application/rss+xml, application/xml, text/xml, */*',
        },
        redirect: 'follow',
      });
      if (res.ok) return res;
      lastErr = new Error(`HTTP ${res.status}`);
    } catch (e) {
      lastErr = e;
    }
    log(`إعادة محاولة ${feedOf(url)} (${i}/${attempts})...`);
    await new Promise((r) => setTimeout(r, 3000 * i));
  }
  throw lastErr;
}

function feedOf(url) {
  const f = FEEDS.find((x) => x.url === url);
  return f ? f.name : url;
}

async function fetchFeed(feed) {
  log(`سحب الخلاصة: ${feed.name}`);
  const res = await fetchWithRetry(feed.url);
  const xml = await res.text();

  const parser = new XMLParser({
    ignoreAttributes: false,
    attributeNamePrefix: '@_',
    removeNSPrefix: false,
    trimValues: true,
    cdataPropName: '__cdata',
    isArray: (name) => ['item', 'entry', 'media:content', 'media:thumbnail'].includes(name),
  });
  const parsed = parser.parse(xml);
  const channel = parsed.rss?.channel;
  const atomFeed = parsed.feed;
  const rawItems = channel?.item || atomFeed?.entry || [];

  return rawItems
    .map((it) => normalizeItem(it, feed.name))
    .filter((it) => it && it.title && it.link);
}

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

function extractImage(item) {
  const m = item['media:content']?.[0] ?? item['media:content'];
  const t = item['media:thumbnail']?.[0] ?? item['media:thumbnail'];
  const e = item.enclosure;
  return pickValue(m) || pickValue(t) || (e && pickValue(e));
}

function normalizeItem(raw, source) {
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

function decodeEntities(str) {
  const named = {
    nbsp: ' ', amp: '&', quot: '"', apos: "'", lt: '<', gt: '>',
    hellip: '…', mdash: '—', ndash: '–', rsquo: '’', lsquo: '‘',
    rdquo: '”', ldquo: '“', middot: '·', trade: '™', copy: '©',
  };
  return String(str || '')
    .replace(/&#(\d+);/g, (_, d) => String.fromCharCode(parseInt(d, 10)))
    .replace(/&#x([0-9a-fA-F]+);/g, (_, h) => String.fromCharCode(parseInt(h, 16)))
    .replace(/&([a-z]+);/gi, (m, n) => named[n.toLowerCase()] ?? m);
}

function stripHtml(html) {
  return decodeEntities(String(html || '')
    .replace(/<[^>]*>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim());
}

function extractJsonBlock(text) {
  const start = text.indexOf('[');
  const end = text.lastIndexOf(']');
  if (start !== -1 && end > start) {
    try {
      return JSON.parse(text.slice(start, end + 1));
    } catch {
      /* تجاهل وحاول التحليل الكامل */
    }
  }
  return JSON.parse(text);
}

async function summarizeBatch(items, feedName) {
  const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
  const model = genAI.getGenerativeModel({
    model: GEMINI_MODEL,
    generationConfig: {
      temperature: 0.4,
      responseMimeType: 'application/json',
    },
  });

  const input = items
    .map((it, i) => JSON.stringify({ id: i, title: it.title, description: it.description, pubDate: it.pubDate }))
    .join('\n');

  const prompt = `أنت محرر أخبار تقنية عربي. أعِد صياغة الأخبار التالية وترجمتها إلى العربية.
القواعد:
- لكل خبر: عنوان عربي جذاب ومختصر (لا يتجاوز 80 حرفاً)، وملخص مركز في 3 أسطر فقط (افصل بين الأسطر بعلامة \n).
- إذا كان النص عربياً أصلاً فأعِد صياغته بالعربية الفصحى، وإن كان إنجليزياً فترجمه ترجمة احترافية.
- حدد تصنيفاً واحداً لكل خبر من القائمة حصراً: ${CATEGORIES.join('، ')}
- أعد JSON على شكل مصفوفة بنفس عدد المدخلات وبنفس معرف id، بصيغة:
[{"id":0,"title":"...","summary":"سطر1\\nسطر2\\nسطر3","category":"ذكاء اصطناعي"}]

الأخبار:
${input}`;

  log(`تلخيص ${items.length} خبراً من ${feedName} عبر ${GEMINI_MODEL}...`);
  const result = await model.generateContent(prompt);
  const text = result.response.text();
  let arr;
  try {
    arr = extractJsonBlock(text);
  } catch (e) {
    throw new Error(`تعذر تحليل استجابة Gemini (JSON): ${e.message}\n${text.slice(0, 300)}`);
  }
  if (!Array.isArray(arr)) throw new Error('استجابة Gemini ليست مصفوفة');

  const byId = new Map(arr.map((x) => [Number(x.id), x]));
  return items.map((it, i) => {
    const g = byId.get(i) || {};
    return {
      ...it,
      title: g.title || it.title,
      content: g.summary || stripHtml(it.description).slice(0, 300),
      category: CATEGORIES.includes(g.category) ? g.category : 'تقنية عامة',
    };
  });
}

async function imageToBase64(url) {
  try {
    const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0 (compatible; PortfolioNewsFetcher/1.0)' }, redirect: 'follow' });
    if (!res.ok) return null;
    const buf = Buffer.from(await res.arrayBuffer());
    if (buf.length > 300 * 1024) return null;
    const mime = res.headers.get('content-type')?.split(';')[0] || 'image/jpeg';
    return `data:${mime};base64,${buf.toString('base64')}`;
  } catch {
    return null;
  }
}

function toTimestamp(d) {
  const dt = d instanceof Date && !isNaN(d) ? d : new Date();
  if (db) return admin.firestore.Timestamp.fromDate(dt);
  return dt.toISOString();
}

function buildDoc(it, preview = false) {
  const fallbackContent = stripHtml(it.description || '').slice(0, 300) || it.title || '';
  const base = {
    title: it.title || '',
    content: it.content || fallbackContent,
    description: it.content || fallbackContent,
    source: it.source || '',
    category: it.category || 'تقنية عامة',
    link: it.link || '',
    publishedAt: it.pubDate || null,
    createdAt: preview ? new Date().toISOString() : admin.firestore.Timestamp.now(),
  };
  base.date = toTimestamp(it.pubDate ? new Date(it.pubDate) : new Date());
  if (it.imageBase64) base.imageBase64 = it.imageBase64;
  return base;
}

async function isDuplicate(link) {
  if (dryRun) return false;
  const snap = await db.collection('news').where('link', '==', link).limit(1).get();
  return !snap.empty;
}

async function saveItem(it) {
  const doc = buildDoc(it, dryRun);
  if (dryRun) {
    log(`[تجريبي] سيُحفظ: "${doc.title}" | ${doc.source} | ${doc.link} | ${doc.category}`);
    return 'dry-run';
  }
  await db.collection('news').add(doc);
  return 'saved';
}

async function main() {
  if (GEMINI_API_KEY) {
    log('Gemini API: متاح');
  } else {
    log('تنبيه: GEMINI_API_KEY غير مضبوط — سيتم استخدام العناوين الأصلية دون تلخيص.');
  }

  if (dryRun) {
    log('وضع التجربة (DRY_RUN=true): لن يتم الحفظ في Firestore.');
  } else {
    if (!FIREBASE_SERVICE_ACCOUNT) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT مفقود — لا يمكن الحفظ بدون مفتاح الخدمة.');
    }
    const sa = JSON.parse(FIREBASE_SERVICE_ACCOUNT);
    admin.initializeApp({ credential: admin.credential.cert(sa) });
    db = admin.firestore();
    db.settings({ ignoreUndefinedProperties: true });
    log(`Firestore جاهز على مشروع: ${sa.project_id || 'غير معروف'}`);
  }

  const fresh = [];
  for (const feed of FEEDS) {
    try {
      const items = await fetchFeed(feed);
      if (!items.length) {
        log(`${feed.name}: لا توجد عناصر.`);
        continue;
      }
      log(`${feed.name}: تم جلب ${items.length} عنصراً.`);
      const top = items.slice(0, maxItemsPerFeed);

      let summarized = top;
      if (GEMINI_API_KEY) {
        try {
          summarized = await summarizeBatch(top, feed.name);
        } catch (e) {
          log(`تحذير: فشل تلخيص ${feed.name}: ${e.message} — سيُستخدم النص الأصلي.`);
          summarized = top.map((it) => ({
            ...it,
            content: it.description.slice(0, 300) || it.title,
            category: 'تقنية عامة',
          }));
        }
      } else {
        summarized = top.map((it) => ({
          ...it,
          content: it.description.slice(0, 300) || it.title,
          category: 'تقنية عامة',
        }));
      }

      for (const it of summarized) {
        if (await isDuplicate(it.link)) {
          log(`تخطي (مكرر): ${it.link}`);
          continue;
        }
        if (fetchImages && it.imageUrl) {
          it.imageBase64 = await imageToBase64(it.imageUrl);
        }
        fresh.push(it);
      }
    } catch (e) {
      log(`خطأ في المصدر ${feed.name}: ${e.message}`);
    }
  }

  if (!fresh.length) {
    log('لا توجد أخبار جديدة للحفظ.');
    return;
  }

  let savedCount = 0;
  for (const it of fresh) {
    try {
      await saveItem(it);
      savedCount++;
    } catch (e) {
      log(`فشل حفظ: ${it.link}: ${e.message}`);
    }
  }
  log(`تمت معالجة ${fresh.length} خبراً جديداً، الحفظ الناجح: ${savedCount}.`);
}

const isMain = process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;
if (isMain) {
  main().then(() => process.exit(0)).catch((e) => {
    console.error('[FATAL]', e);
    process.exit(1);
  });
}

export { buildDoc, toTimestamp, stripHtml, decodeEntities, normalizeItem, CATEGORIES };
