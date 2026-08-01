/**
 * جلب أخبار التقنية اليومية من خلاصات RSS وتلخيصها وترجمتها إلى العربية
 * عبر Google Gemini، ثم تخزينها في Firebase Firestore (مجموعة news).
 *
 * المتغيرات البيئية المطلوبة:
 *   GEMINI_API_KEY            مفتاح Google Gemini API (إلزامي للتحرير الذكي والفلترة)
 *   FIREBASE_SERVICE_ACCOUNT  محتوى JSON لمفتاح الخدمة (إلزامي للحفظ)
 *   GEMINI_MODEL              النموذج المستخدم (الافتراضي gemini-2.0-flash)
 *   MAX_ITEMS_PER_FEED        عدد العناصر المسحوبة من كل مصدر لعرضها على المحرر (الافتراضي 10)
 *   MAX_PUBLISHED             الحد الأقصى للأخبار المنشورة بعد الفلترة (الافتراضي 10)
 *   FETCH_IMAGES              جلب صورة الخبر وتخزينها base64 (الافتراضي true)
 *   DRY_RUN                   true = تجربة بدون الحفظ الفعلي (الافتراضي false)
 *   REFRESH_EXISTING          true = إعادة ترجمة الأخبار الإنجليزية المخزنة (الافتراضي false)
 *   WIPE_FIRST                true = مسح مجموعة news بالكامل قبل المعالجة (الافتراضي false)
 */
import admin from 'firebase-admin';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { XMLParser } from 'fast-xml-parser';
import { pathToFileURL } from 'node:url';

const {
  GEMINI_API_KEY,
  FIREBASE_SERVICE_ACCOUNT,
  GEMINI_MODEL = 'gemini-2.0-flash',
  MAX_ITEMS_PER_FEED = '10',
  MAX_PUBLISHED = '10',
  FETCH_IMAGES = 'true',
  DRY_RUN = 'false',
  REFRESH_EXISTING = 'false',
  WIPE_FIRST = 'false',
} = process.env;

const maxItemsPerFeed = Math.max(1, parseInt(MAX_ITEMS_PER_FEED, 10) || 10);
const maxPublished = Math.max(1, parseInt(MAX_PUBLISHED, 10) || 10);
const fetchImages = FETCH_IMAGES === 'true';
const dryRun = DRY_RUN === 'true';
const refreshExisting = REFRESH_EXISTING === 'true';
const wipeFirst = WIPE_FIRST === 'true';

const FEEDS = [
  { name: 'TechCrunch', url: 'https://techcrunch.com/feed/' },
  { name: 'The Verge', url: 'https://www.theverge.com/rss/index.xml' },
  { name: 'أخبار التقنية (aitnews)', url: 'https://aitnews.com/feed/' },
];

const CATEGORIES = ['أجهزة', 'ذكاء اصطناعي', 'استحواذات', 'شركات تقنية', 'سيارات ذكية'];

let db = null;

function log(...args) {
  console.log(new Date().toISOString(), ...args);
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

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

const WEAK_PATTERNS = [
  /\breview\b/i, /\bbest\b/i, /\bgift/i, /\bguide\b/i, /\bhow[- ]to\b/i,
  /\bshopping\b/i, /\bdeals?\b/i, /\bsale\b/i, /\bdiscount/i, /\bcoupon\b/i,
  /\btips\b/i, /\bbuy\b/i, /\btop \d+/i, /\bhats?\b/i, /\bfans?\b/i,
  /\brecommend/i, /\bcheap/i, /\bunder \$/i, /\bgiveaway/i, /\bessentials\b/i,
  /\bback[- ]to[- ]school/i, /\bround[- ]up\b/i, /\bbuying\b/i, /\bvs\.?\b/i,
  /\bshould you\b/i, /\bworth it\b/i, /\bopinion\b/i, /\bcolumn\b/i,
];

const AR_WEAK_PATTERNS = [
  /مراجعة/, /دليل/, /أفضل/, /شراء/, /هدايا?/, /نصائح/, /عروض/, /خصومات?/,
  /كوبون/, /مقارنة/, /تسوق/, /تجربة|انطباع/, /أفكار/, /قائمة/,
];

const STRONG_PATTERNS = [
  /\biphone\b/i, /\bgalaxy\b/i, /\bapple\b/i, /\bgoogle\b/i, /\bsamsung\b/i,
  /\bmicrosoft\b/i, /\btesla\b/i, /\blucid\b/i, /\bgpt\b/i, /\bopena[ií]/i,
  /\bclaude\b/i, /\bcopilot\b/i, /\bqualcomm\b/i, /\bintel\b/i, /\bamd\b/i,
  /\bnvidia\b/i, /\bchip\b/i, /\bprocessor\b/i, /\bacquisition\b/i,
  /\bacquires\b/i, /\bmerger\b/i, /\bipo\b/i, /\bai\b/i,
  /artificial intelligence/i, /\bquantum\b/i, /\bsemiconductor/i,
  /\btelecom/i, /\b5g\b/i, /\b6g\b/i, /\bleak/i, /\brobot/i, /\bev\b/i,
  /\belectric vehicle/i, /\bsmartphone\b/i, /\btablet\b/i, /\blaptop\b/i,
  /\bwatch\b/i, /\bheadset\b/i, /\bar\b/i, /\bvr\b/i, /\bcloud\b/i,
  /\bsatellite\b/i, /\bsolar\b/i, /\bbattery\b/i,
];

function isWorthPublishing(it) {
  const title = String(it.title || '');
  const text = `${title} ${String(it.description || '')}`;
  if (hasArabic(text)) {
    if (AR_WEAK_PATTERNS.some((re) => re.test(text))) return false;
    return true;
  }
  if (WEAK_PATTERNS.some((re) => re.test(text))) return false;
  return STRONG_PATTERNS.some((re) => re.test(text));
}

async function localFilterAndTranslate(items) {
  const kept = items.filter(isWorthPublishing);
  const rejected = items.length - kept.length;
  if (rejected > 0) log(`الفلترة المحلية: رفض ${rejected} خبراً ضعيفاً (أدلة/مراجعات/رأي).`);
  return Promise.all(kept.map(arabicFallback));
}

async function translateText(text) {
  if (!text || hasArabic(text)) return text;
  const url = 'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=ar&dt=t&q=' + encodeURIComponent(text);
  const res = await fetch(url, {
    headers: { 'User-Agent': 'Mozilla/5.0 (compatible; PortfolioNewsFetcher/1.0)' },
    redirect: 'follow',
    signal: AbortSignal.timeout(15000),
  });
  if (!res.ok) throw new Error(`حالة استجابة الترجمة ${res.status}`);
  const data = await res.json();
  const translated = Array.isArray(data?.[0]) ? data[0].map((seg) => seg?.[0] || '').join('') : '';
  const cleaned = String(translated).replace(/\s+/g, ' ').trim();
  if (!hasArabic(cleaned)) throw new Error('الترجمة الناتجة غير عربية');
  return cleaned;
}

async function arabicFallback(it) {
  const enriched = { ...it };
  const rawTitle = it.title || '';
  const rawContent = stripHtml(it.description || '').slice(0, 600) || rawTitle;
  try {
    const [title, content] = await Promise.all([
      translateText(rawTitle),
      translateText(rawContent),
    ]);
    enriched.originalTitle = rawTitle;
    enriched.title = title;
    enriched.content = content;
  } catch (e) {
    log(`تنبيه: تعذرت الترجمة المجانية: ${e.message}`);
    enriched.originalTitle = rawTitle;
    enriched.title = rawTitle;
    enriched.content = rawContent;
    enriched._translationFailed = true;
  }
  enriched.category = it.category || 'تقنية عامة';
  return enriched;
}

async function refreshExistingNews() {
  if (dryRun || !db) return 0;
  let updated = 0;
  const snap = await db.collection('news').get();
  for (const doc of snap.docs) {
    const d = doc.data();
    const title = String(d.title || '');
    if (!title || hasArabic(title)) continue;
    log(`إعادة ترجمة خبر إنجليزي مخزّن: ${title.slice(0, 60)}`);
    try {
      const newTitle = await translateText(title);
      const newContent = await translateText(String(d.content || d.description || title).slice(0, 600));
      await doc.ref.set(
        {
          title: newTitle,
          content: newContent,
          description: newContent,
          originalTitle: title,
          _translatedAt: admin.firestore.Timestamp.now(),
        },
        { merge: true }
      );
      updated++;
    } catch (e) {
      log(`فشل إعادة الترجمة: ${title.slice(0, 60)}: ${e.message}`);
    }
    await sleep(300);
  }
  return updated;
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

  const prompt = `أنت "مدير تحرير تقني" في موقع عربي تقني محترف. ستستلم أخباراً تقنية خام من خلاصات RSS عناوينها ومحتواها قد تكون بالإنجليزية أو العربية.

أولاً — الانتقاء (الفلترة):
لكل خبر اقرأ عنوانه ومحتواه ثم احكم: قَبول أم رفض؟
- قَبول إذا كان من النوع التقني الثقيل والجاذب للقارئ العربي مثل: إطلاق هواتف وأجهزة جديدة، مؤتمرات وإعلانات الشركات الكبرى (Apple / Google / Samsung / Microsoft)، تسريبات الأجهزة القادمة، تطورات وتحديثات الذكاء الاصطناعي، استحواذات وصفقات الشركات، أخبار السيارات الذكية والكهربائية (Tesla / Lucid).
- رفض فوراً إذا كان: مقال رأي شخصي، دليل شراء أو تسوق، مراجعة جهاز بسيط (مروحة، قبعة، ملحق رخيص)، محتوى عام أو ترفيهي، محتوى موسمي (عروض، هدايا، نصائح شراء)، أو خبراً ضعيفاً لا قيمة حقيقية له.

ثانياً — الصياغة الصحفية (للمقبول فقط):
- أعد صياغة العنوان بالعربية بأسلوب صحفي مشوق وجذاب يحفز القراءة، دقيق وغير مبالغ، ولا يتجاوز 90 حرفاً. مثال: بدلاً من "تحديث تطبيق" اكتب "جوجل تطلق تحديثاً ثورياً لتطبيقاتها.. إليك أبرز الميزات".
- اكتب ملخصاً من 3 إلى 4 أسطر غنياً بالمعلومات الحقيقية المستخرجة من النص (المواصفات، الأسعار، التواريخ، التفاصيل المعلنة) بحيث يكتفي القارئ بفتح البطاقة ليعرف الجوهر.

قواعد صارمة:
1. كل المخرجات بالعربية حصراً؛ أسماء العلم والشركات والمنتجات الأجنبية (OpenAI، Apple، iPhone، Tesla) تبقى بحروفها اللاتينية.
2. لا تختلق معلومات غير موجودة في النص الأصلي إطلاقاً.
3. أعد JSON على شكل مصفوفة بنفس عدد المدخلات وبنفس المعرفات id، لكل عنصر بالصيغة:
{"id":0,"publish":true,"reason":"سبب موجز للقبول أو الرفض","title":"العنوان العربي المشوق","summary":"سطر1\\nسطر2\\nسطر3","category":"أجهزة"}
- للمرفوض: publish=false و reason يوضح السبب، واترك title و summary فارغين.
- التصنيف category من القائمة حصراً: ${CATEGORIES.join('، ')}
- إن كان عدد المقبولين قليلاً فاكتفِ بهم ولا تحاول حشو صفحة بأخبار ضعيفة.

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
  const acceptedResp = arr.filter((x) => x?.publish === true);
  if (acceptedResp.length && !acceptedResp.every(isArabicTitle)) {
    log('تنبيه: بعض العناوين المقبولة غير عربية — إعادة محاولة بتعليمات أشد.');
    try {
      arr = await generateOnce(
        `${prompt}\n\nتذكير صارم أخير: العنوان يجب أن يكون صياغة عربية حقيقية للخبر المقبول 100% عدا أسماء العلم والشركات، والملخص بالعربية. إن كانت أي استجابة publish=true وعنوانها بالإنجليزية فأعد صياغتها بالعربية قبل الإجابة.`
      );
    } catch (e) {
      log(`إعادة المحاولة فشلت: ${e.message} — سيُستخدم ما ورد.`);
    }
  }

  const hasPublishFlag = arr.some((x) => typeof x?.publish === 'boolean');
  const byId = new Map(arr.map((x) => [Number(x.id), x]));
  const accepted = [];
  for (let i = 0; i < items.length; i++) {
    const it = items[i];
    const g = byId.get(i) || {};
    const isAccepted = hasPublishFlag ? g.publish === true : hasArabic(g.title || '');
    if (!isAccepted) {
      log(`رفض بعد الفلترة: ${String(it.title).slice(0, 70)}${g.reason ? ` — ${g.reason}` : ''}`);
      continue;
    }
    const title = hasArabic(g.title || '') ? g.title : '';
    const content = hasArabic(g.summary || '') ? g.summary : '';
    let fallback = null;
    if (!title || !content) fallback = await arabicFallback(it);
    const finalTitle = title || (fallback && fallback.title) || it.title;
    const finalContent = content || (fallback && fallback.content) || stripHtml(it.description || '').slice(0, 300);
    if (!hasArabic(finalTitle)) {
      log(`تخطي (عنوان غير عربي بعد الترجمة): ${String(it.title).slice(0, 60)}`);
      continue;
    }
    accepted.push({
      ...it,
      title: finalTitle,
      content: finalContent,
      category: CATEGORIES.includes(g.category) ? g.category : 'تقنية عامة',
      _translationFailed: fallback ? fallback._translationFailed : false,
    });
  }
  return accepted;
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

async function wipeNews() {
  if (dryRun || !db) return 0;
  let deleted = 0;
  const snap = await db.collection('news').get();
  for (const doc of snap.docs) {
    await doc.ref.delete();
    deleted++;
  }
  if (deleted > 0) log(`تم مسح ${deleted} خبراً من مجموعة news للبدء بنشرة جديدة.`);
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
    if (wipeFirst) {
      await wipeNews();
    }
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
        if (!summarized.length) log('Gemini: لم يتبقَّ خبر جدير بالنشر بعد الفلترة.');
        else log(`Gemini: تم قبول ${summarized.length} خبراً جديراً بالنشر من أصل ${allItems.length}.`);
      } catch (e) {
        log(`تحذير: فشل تلخيص Gemini: ${e.message} — فلترة محلية + ترجمة مجانية.`);
        summarized = await localFilterAndTranslate(allItems);
      }
    } else {
      log('تنبيه: GEMINI_API_KEY غير مضبوط — فلترة محلية + ترجمة مجانية.');
      summarized = await localFilterAndTranslate(allItems);
    }
  }
  summarized = summarized.slice(0, maxPublished);

  const fresh = [];
  const pendingUpdate = [];
  for (const it of summarized) {
    if (!hasArabic(it.title || '')) {
      log(`تخطي (عنوان غير عربي بعد الترجمة): ${String(it.title).slice(0, 60)}`);
      continue;
    }
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

  if (refreshExisting && !dryRun) {
    const refreshed = await refreshExistingNews();
    if (refreshed > 0) log(`تمت إعادة ترجمة ${refreshed} خبراً إنجليزياً مخزّناً.`);
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
  translateText,
  isWorthPublishing,
  localFilterAndTranslate,
  wipeNews,
  refreshExistingNews,
  CATEGORIES,
};
