#!/usr/bin/env node
/**
 * النشر التلقائي اليومي على منصة X:
 *  1) يختار أهم خبر/ترند من مجموعة التحديثات (tech_news ← google_trends ← saudi_news ← global_news ← twitter_trends)
 *  2) يصوغ تغريدة احترافية بالعربية عبر Gemini (إيموجي + هاشتاجات + رابط الحساب)
 *  3) ينشرها مرة واحدة يومياً عبر twitter-api-v2
 *
 * المتغيرات البيئية:
 *   GEMINI_API_KEY, FIREBASE_SERVICE_ACCOUNT, GEMINI_MODEL, DRY_RUN,
 *   X_API_KEY, X_API_SECRET, X_ACCESS_TOKEN, X_ACCESS_SECRET, X_PROFILE_URL
 */
import { GoogleGenerativeAI } from '@google/generative-ai';
import { TwitterApi } from 'twitter-api-v2';
import { log, hasArabic, translateText } from './lib/core.js';
import { initFirestore, getDb } from './lib/firestore.js';

const {
  GEMINI_API_KEY,
  FIREBASE_SERVICE_ACCOUNT,
  GEMINI_MODEL = 'gemini-2.0-flash',
  DRY_RUN = 'false',
  X_API_KEY,
  X_API_SECRET,
  X_ACCESS_TOKEN,
  X_ACCESS_SECRET,
  X_PROFILE_URL = 'https://x.com/abowaaleed',
} = process.env;

const dryRun = DRY_RUN === 'true';
const COLLECTIONS = ['tech_news', 'google_trends', 'saudi_news', 'global_news', 'twitter_trends'];

async function pickTopStory() {
  const db = getDb();
  for (const c of COLLECTIONS) {
    try {
      const snap = await db.collection(c).orderBy('createdAt', 'desc').limit(3).get();
      if (snap.empty) continue;
      const doc = snap.docs[0];
      const data = doc.data();
      if (data && data.title) {
        return { collection: c, id: doc.id, data };
      }
    } catch (e) {
      log(`تعذر قراءة ${c}: ${e.message}`);
    }
  }
  return null;
}

async function craftTweet(story) {
  const data = story.data;
  const context = `المصدر: ${story.collection}\nالعنوان: ${data.title}\n${data.summary || data.content || ''}\nالرابط: ${data.url || data.link || ''}`;
  if (GEMINI_API_KEY) {
    try {
      const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
      const model = genAI.getGenerativeModel({
        model: GEMINI_MODEL,
        generationConfig: { temperature: 0.8 },
      });
      const prompt = `أنت متخصص في التسويق والإعلام على منصة X. أمامك أهم خبر/ترند تقني سعودي اليوم:
---
${context}
---
اكتب تغريدة واحدة بالعربية الفصحى السلسة:
- أسلوب مشوق وجذاب يشد القارئ، مع إيموجي أو اثنين مناسبين.
- من 2 إلى 3 هاشتاجات: #تقنية #السعودية وهاشتاج متعلق بالموضوع.
- لا تتجاوز 270 حرفاً.
- في نهاية التغريدة ضع رابط الحساب: ${X_PROFILE_URL}
أعد نص التغريدة فقط دون أي مقدمات.`;
      const res = await model.generateContent(prompt);
      const text = String(res.response.text() || '').trim();
      if (hasArabic(text) && text.length <= 280) return text;
      log('التغريدة المولدة غير صالحة، استخدام البديل.');
    } catch (e) {
      log(`فشل توليد التغريدة عبر Gemini: ${e.message}`);
    }
  }

  const title = hasArabic(data.title) ? data.title : (await translateText(data.title).catch(() => data.title));
  const summary = String(data.summary || data.content || '').replace(/\n+/g, ' ').slice(0, 120);
  const url = data.url || data.link || '';
  return `${title}\n\n${summary}${url ? `\n${url}` : ''}\n\n#تقنية #السعودية\n${X_PROFILE_URL}`.slice(0, 280);
}

async function main() {
  if (!FIREBASE_SERVICE_ACCOUNT) throw new Error('FIREBASE_SERVICE_ACCOUNT مفقود.');
  initFirestore(FIREBASE_SERVICE_ACCOUNT);

  const story = await pickTopStory();
  if (!story) {
    log('لا يوجد خبر أو ترند للنشر اليوم.');
    process.exit(0);
  }
  log(`تم اختيار: ${story.collection} — ${String(story.data.title).slice(0, 70)}`);

  const tweet = await craftTweet(story);
  if (dryRun) {
    log('——— مسودة التغريدة (DRY_RUN) ———');
    console.log(tweet);
    console.log(`[طول: ${tweet.length} حرفاً]`);
    process.exit(0);
  }

  if (!X_API_KEY || !X_API_SECRET || !X_ACCESS_TOKEN || !X_ACCESS_SECRET) {
    log('تنبيه: مفاتيح X مفقودة (X_API_KEY, X_API_SECRET, X_ACCESS_TOKEN, X_ACCESS_SECRET) — سيتم تخطي النشر دون فشل.');
    process.exit(0);
  }

  const client = new TwitterApi({
    appKey: X_API_KEY,
    appSecret: X_API_SECRET,
    accessToken: X_ACCESS_TOKEN,
    accessSecret: X_ACCESS_SECRET,
  });
  const result = await client.v2.tweet(tweet);
  log(`تم نشر التغريدة بنجاح: ${result.data?.id || ''}`);
}

main().then(() => process.exit(0)).catch((e) => {
  console.error('[FATAL]', e);
  process.exit(1);
});
