/**
 * جلب أخبار التقنية اليومية من خلاصات RSS وتلخيصها وترجمتها إلى العربية
 * عبر Google Gemini، ثم تخزينها في Firebase Firestore (مجموعة news).
 *
 * المتغيرات البيئية المطلوبة:
 *   GEMINI_API_KEY            مفتاح Google Gemini API (إلزامي للتلخيص)
 *   FIREBASE_SERVICE_ACCOUNT  محتوى JSON لمفتاح الخدمة (إلزامي للحفظ)
 *   GEMINI_MODEL              النموذج المستخدم (الافتراضي gemini-2.0-flash)
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

function hasArabic(text) {
  return /[\u0600-\u06FF]/.test(String(text || ''));
}

function arabicFallback(it) {
  const enriched = { ...it };
  const rawContent = stripHtml(it.description || '').slice(0, 600) || it.title || '';
  enriched.originalTitle = it.title || '';
  enriched.title = it.title || '';
  enriched.content = rawContent;
  enriched.category = it.category || 'تقنية عامة';
  return enriched;
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

  const prompt = `أنت محرر أخبار تقنية محترف يجيد العربية الفصحى. ستستلم أخباراً تقنية قد تكون عناوينها ومحتواها بالإنجليزية أو العربية.

مهمتك لكل خبر:
- ترجم العنوان الأصلي ترجمةً دقيقة وكاملة إلى العربية الفصحى. العنوان المترجم يجب أن يكون العنوان الحقيقي للخبر نفسه بنفس معناه — وليس وصفاً عاماً أو مختصراً.
- اكتب ملخصاً شاملاً للخبر من 3 إلى 5 أسطر يغطي جوهر القصة: ماذا حدث، ولفائدة من، وما الأثر المتوقع.

قواعد صارمة:
1. كل المخرجات (العنوان والملخص) بالعربية حصراً — لا تكتب جملة كاملة بالإنجليزية أبداً.
2. أسماء العلم والشركات والمنتجات الأجنبية (مثل OpenAI وApple وSiri وGoogle) تُكتب بحروفها اللاتينية لأنها أسماء علمية، وبقية الجملة عربية بالكامل.
3. ممنوع استخدام عبارات عامة في العنوان مثل "خبر تقني جديد" أو "أعلنت شركة عن إطلاق..." — العنوان يجب أن يكون ترجمة أمينة للعنوان الأصلي.
4. العنوان: مختصر وجذاب (لا يتجاوز 80 حرفاً).
5. الملخص: من 3 إلى 5 أسطر، وافصل بين الأسطر بعلامة \n.
6. حدد تصنيفاً واحداً لكل خبر من القائمة حصراً: ${CATEGORIES.join('، ')}
7. أعد JSON على شكل مصفوفة بنفس عدد المدخلات وبنفس معرف id، بصيغة:
[{"id":0,"title":"العنوان المترجم","summary":"سطر1\\nسطر2\\nسطر3\\nسطر4","category":"ذكاء اصطناعي"}]

الأخبار:
${input}`;

  async function generateWithRetry(promptText, attempts = 3) {
    let lastErr;
    for (let i = 1; i <= attempts; i++) {
      try {
        return await model.generateContent(promptText);
      } catch (e) {
        lastErr = e;
        const msg = String(e.message || '');
        const retryable = /(429|408|500|502|503|504|quota|rate.?limit|RESOURCE_EXHAUSTED|UNAVAILABLE)/i.test(msg);
        if (!retryable || i === attempts) throw e;
        const m = msg.match(/retry in ([0-9.]+)s/i);
        const delay = m ? Math.ceil(parseFloat(m[1]) * 1000) + 1500 : (i === 1 ? 20000 : 40000);
        log(`خطأ Gemini مؤقت (محاولة ${i}/${attempts}): ${msg.slice(0, 140)} — إعادة المحاولة بعد ${Math.round(delay / 1000)} ثانية.`);
        await new Promise((r) => setTimeout(r, delay));
      }
    }
    throw lastErr;
  }

  async function generateOnce(p) {
    const result = await generateWithRetry(p);
    return extractJsonBlock(result.response.text());
  }

  log(`تلخيص ${items.length} خبراً من ${feedName} عبر ${GEMINI_MODEL}...`);
  let arr;
  try {
    arr = await generateOnce(prompt);
  } catch (e) {
    throw new Error(`تعذر تحليل استجابة Gemini (JSON): ${e.message}`);
  }
  if (!Array.isArray(arr)) throw new Error('استجابة Gemini ليست مصفوفة');

  const isArabicTitle = (x) => hasArabic(x?.title || '');
  if (!arr.every(isArabicTitle)) {
    log('تنبيه: بعض العناوين غير عربية — إعادة محاولة بتعليمات أشد.');
    try {
      arr = await generateOnce(
        `${prompt}\n\nتذكير صارم أخير: العنوان يجب أن يكون ترجمة عربية حقيقية للعنوان الأصلي 100% عدا أسماء العلم والشركات. إن كان أي عنوان بالإنجليزية فأعد ترجمته الآن قبل الإجابة. الملخص أيضاً يجب أن يكون بالعربية.`
      );
    } catch (e) {
      log(`إعادة المحاولة فشلت: ${e.message} — سيُستخدم النص كما ورد.`);
    }
  }

  const byId = new Map(arr.map((x) => [Number(x.id), x]));
  return items.map((it, i) => {
    const g = byId.get(i) || {};
    const fallback = arabicFallback(it);
    return {
      ...it,
      title: hasArabic(g.title || '') ? g.title : fallback.title,
      content: hasArabic(g.summary || '') ? g.summary : fallback.content,
      category: CATEGORIES.includes(g.category) ? g.category : 'تقنية عامة',
    };
  });
}

async function imageToBase64(url) {
  try {
    const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0 (compatible; PortfolioNewsFetcher/1.0)' }, redirect: 'follow' });
    if (!res.ok) return null;
    const buf = Buffer.from(await res.arrayBuffer());
    if (buf.length > 500 * 1024) return null;
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
    url: it.link || '',
    publishedAt: it.pubDate || null,
    createdAt: preview ? new Date().toISOString() : admin.firestore.Timestamp.now(),
  };
  base.date = toTimestamp(it.pubDate ? new Date(it.pubDate) : new Date());
  base.originalTitle = it.originalTitle || it.title || '';
  if (it.imageUrl) base.imageUrl = it.imageUrl;
  if (it.imageBase64) base.imageBase64 = it.imageBase64;
  return base;
}

async function findExisting(link) {
  if (dryRun) return null;
  const snap = await db.collection('news').where('link', '==', link).limit(1).get();
  return snap.empty ? null : snap.docs[0];
}

async function saveItem(it) {
  const doc = buildDoc(it, dryRun);
  if (dryRun) {
    log(`[تجريبي] سيُحفظ: "${doc.title}" | ${doc.source} | ${doc.link} | ${doc.category}${doc.imageBase64 ? ' | مع صورة' : ''}`);
    return 'dry-run';
  }
  await db.collection('news').add(doc);
  return 'saved';
}

async function cleanEnglishNews(savedLinks = new Set()) {
  if (dryRun) return 0;
  let deleted = 0;
  const snap = await db.collection('news').get();
  for (const doc of snap.docs) {
    const d = doc.data();
    const title = String(d.title || '');
    const link = String(d.link || '');
    if (title && !hasArabic(title) && !savedLinks.has(link)) {
      await doc.ref.delete();
      deleted++;
      log(`حذف خبر إنجليزي قديم: ${title.slice(0, 60)}`);
    }
  }
  return deleted;
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

  const allItems = [];
  for (const feed of FEEDS) {
    try {
      const items = await fetchFeed(feed);
      if (!items.length) {
        log(`${feed.name}: لا توجد عناصر.`);
        continue;
      }
      log(`${feed.name}: تم جلب ${items.length} عنصراً.`);
      allItems.push(...items.slice(0, maxItemsPerFeed));
    } catch (e) {
      log(`خطأ في المصدر ${feed.name}: ${e.message}`);
    }
  }

  let summarized = allItems;
  if (allItems.length) {
    if (GEMINI_API_KEY) {
      try {
        summarized = await summarizeBatch(allItems, 'جميع المصادر');
      } catch (e) {
        log(`تحذير: فشل تلخيص Gemini: ${e.message} — سيُستخدم البديل (العناوين الأصلية).`);
        summarized = allItems.map(arabicFallback);
      }
    } else {
      log('تنبيه: GEMINI_API_KEY غير مضبوط — سيتم استخدام العناوين الأصلية دون ترجمة.');
      summarized = allItems.map(arabicFallback);
    }
  }

  const fresh = [];
  const pendingUpdate = [];
  for (const it of summarized) {
    const existing = await findExisting(it.link);
    if (existing) {
      const oldTitle = String(existing.data().title || '');
      const newTitle = String(it.title || '');
      if (hasArabic(newTitle) && !hasArabic(oldTitle)) {
        pendingUpdate.push({ it, existing });
      } else {
        log(`تخطي (مكرر): ${it.link}`);
      }
      continue;
    }
    if (fetchImages && it.imageUrl) {
      it.imageBase64 = await imageToBase64(it.imageUrl);
    }
    fresh.push(it);
  }

  if (!fresh.length && !pendingUpdate.length) {
    log('لا توجد أخبار جديدة للحفظ.');
    return;
  }

  let savedCount = 0;
  const savedLinks = new Set();
  for (const it of fresh) {
    try {
      await saveItem(it);
      savedCount++;
      savedLinks.add(it.link);
    } catch (e) {
      log(`فشل حفظ: ${it.link}: ${e.message}`);
    }
  }

  let updatedCount = 0;
  for (const { it, existing } of pendingUpdate) {
    try {
      const doc = buildDoc(it);
      await existing.ref.set(doc, { merge: true });
      updatedCount++;
      savedLinks.add(it.link);
      log(`تم تحديث ترجمة عربية بدلاً من الإنجليزية: ${String(doc.title).slice(0, 60)}`);
    } catch (e) {
      log(`فشل تحديث: ${it.link}: ${e.message}`);
    }
  }
  log(`تمت معالجة ${fresh.length} خبراً جديداً (الحفظ الناجح: ${savedCount}) وتحديث ${updatedCount} ترجمة عربية.`);

  if (!dryRun) {
    const cleaned = await cleanEnglishNews(savedLinks);
    if (cleaned > 0) log(`تم مسح ${cleaned} خبراً إنجليزياً قديماً لعرض الأخبار العربية فقط.`);
  }
}

const isMain = process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;
if (isMain) {
  main().then(() => process.exit(0)).catch((e) => {
    console.error('[FATAL]', e);
    process.exit(1);
  });
}

export {
  buildDoc,
  toTimestamp,
  stripHtml,
  decodeEntities,
  normalizeItem,
  extractFirstImg,
  extractImage,
  hasArabic,
  arabicFallback,
  CATEGORIES,
};
