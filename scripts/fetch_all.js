#!/usr/bin/env node
/**
 * الجالب المتكامل: يسحب الأخبار والترندات من جميع المصادر، يحررها ذكياً عبر Gemini،
 * ويخزنها في مجموعات Firestore منفصلة:
 *   tech_news / google_trends / twitter_trends / saudi_news / global_news
 *
 * المتغيرات البيئية:
 *   GEMINI_API_KEY, FIREBASE_SERVICE_ACCOUNT, GEMINI_MODEL, DRY_RUN,
 *   WIPE_FIRST, MAX_ITEMS_PER_FEED (افتراضي 8), MAX_PUBLISHED (افتراضي 8),
 *   FETCH_IMAGES (افتراضي true)
 */
import { log, hasArabic } from './lib/core.js';
import { initFirestore, saveBatch, wipeCollection, cleanNonArabic, pruneCollection } from './lib/firestore.js';
import {
  fetchAggregate, fetchGoogleTrends, fetchTwitterTrends,
  TECH_FEEDS, SAUDI_FEEDS, GLOBAL_FEEDS,
} from './lib/sources.js';
import {
  editBatch, localFilterAndTranslate, trendsFallback,
  TECH_CATEGORIES, SA_CATEGORIES, GLOBAL_CATEGORIES,
} from './lib/editor.js';
import { filterBlocked } from './lib/moderation.js';

const {
  GEMINI_API_KEY,
  FIREBASE_SERVICE_ACCOUNT,
  DRY_RUN = 'false',
  WIPE_FIRST = 'false',
  MAX_ITEMS_PER_FEED = '8',
  MAX_PUBLISHED = '8',
  FETCH_IMAGES = 'true',
} = process.env;

const dryRun = DRY_RUN === 'true';
const wipeFirst = WIPE_FIRST === 'true';
const maxItemsPerFeed = Math.max(1, parseInt(MAX_ITEMS_PER_FEED, 10) || 8);
const maxPublished = Math.max(1, parseInt(MAX_PUBLISHED, 10) || 8);
const fetchImages = FETCH_IMAGES === 'true';

const COLLECTIONS = ['tech_news', 'google_trends', 'twitter_trends', 'saudi_news', 'global_news'];

const DEFAULT_CATEGORY = {
  tech_news: 'تقنية عامة',
  google_trends: 'ترند',
  twitter_trends: 'ترند',
  saudi_news: 'عام',
  global_news: 'عام',
};

async function runSource(label, collection, items, mode, categories, { requireStrong = false } = {}) {
  if (!items || !items.length) {
    log(`${label}: لا توجد عناصر.`);
    return;
  }
  let edited;
  const fallbackOpts = { requireStrong, defaultCategory: DEFAULT_CATEGORY[collection] || 'تقنية عامة' };
  if (GEMINI_API_KEY) {
    try {
      edited = await editBatch(items, label, { mode, categories });
      log(`${label}: قبل Gemini ${edited.length} عنصراً من أصل ${items.length}.`);
    } catch (e) {
      log(`تحذير: فشل Gemini لـ "${label}": ${e.message} — فلترة محلية + ترجمة مجانية.`);
      edited = mode === 'trends' ? await trendsFallback(items) : await localFilterAndTranslate(items, fallbackOpts);
    }
  } else {
    log(`تنبيه: GEMINI_API_KEY غير مضبوط — بديل محلي لـ "${label}".`);
    edited = mode === 'trends' ? await trendsFallback(items) : await localFilterAndTranslate(items, fallbackOpts);
  }

  edited = edited.filter((it) => hasArabic(it.title || ''));
  const moderated = filterBlocked(edited);
  if (moderated.removed > 0) log(`${label}: استُبعد ${moderated.removed} عنصراً محظوراً قبل التخزين في Firestore.`);
  edited = moderated.kept;
  if (!edited.length) {
    log(`${label}: لا عناصر صالحة للنشر بعد الفلترة.`);
    return;
  }

  const savedUrls = await saveBatch(collection, edited, { dryRun, fetchImages, dedupe: mode !== 'trends', maxPublished });
  if (!dryRun) {
    if (mode !== 'trends') await cleanNonArabic(collection, savedUrls);
    await pruneCollection(collection, 30);
  }
}

async function main() {
  log(GEMINI_API_KEY ? 'Gemini API: متاح' : 'تنبيه: GEMINI_API_KEY غير مضبوط.');
  if (dryRun) {
    log('وضع التجربة (DRY_RUN=true): لن يتم الحفظ في Firestore.');
  } else {
    if (!FIREBASE_SERVICE_ACCOUNT) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT مفقود — لا يمكن الحفظ بدون مفتاح الخدمة.');
    }
    initFirestore(FIREBASE_SERVICE_ACCOUNT);
    if (wipeFirst) {
      for (const c of COLLECTIONS) await wipeCollection(c);
    }
  }

  const tech = await fetchAggregate(TECH_FEEDS, maxItemsPerFeed, 30);
  const trends = await fetchGoogleTrends(12);
  const twitter = await fetchTwitterTrends(12);
  const saudi = await fetchAggregate(SAUDI_FEEDS, maxItemsPerFeed, 20);
  const global = await fetchAggregate(GLOBAL_FEEDS, maxItemsPerFeed, 20);

  await runSource('أخبار التقنية', 'tech_news', tech, 'news', TECH_CATEGORIES, { requireStrong: true });
  await runSource('ترندات جوجل السعودية', 'google_trends', trends, 'trends', ['ترند']);
  await runSource('ترندات X السعودية', 'twitter_trends', twitter, 'trends', ['ترند']);
  await runSource('الأخبار السعودية', 'saudi_news', saudi, 'news', SA_CATEGORIES);
  await runSource('أحداث العالم', 'global_news', global, 'news', GLOBAL_CATEGORIES);

  log('انتهت المعالجة بنجاح.');
}

main().then(() => process.exit(0)).catch((e) => {
  console.error('[FATAL]', e);
  process.exit(1);
});
