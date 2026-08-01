/**
 * "مدير التحرير التقني الذكي":
 *  - فلترة الأخبار الجديرة ورفض الضعيف (أدلة/مراجعات/رأي/ترندات إعلانية)
 *  - صياغة عناوين صحفية مشوقة وملخصات غنية بالمعلومات عبر Gemini
 *  - شرح "لماذا يتصدر هذا الموضوع" للأقسام الترندية
 *  - بديل محلي (أنماط + ترجمة مجانية) عند تعطل Gemini
 */
import { GoogleGenerativeAI } from '@google/generative-ai';
import { log, hasArabic, stripHtml, translateText, extractJsonBlock, sleep } from './core.js';

export const TECH_CATEGORIES = ['أجهزة', 'ذكاء اصطناعي', 'استحواذات', 'شركات تقنية', 'سيارات ذكية'];
export const SA_CATEGORIES = ['سياسي', 'اقتصادي', 'تقني', 'صحي', 'رياضي', 'عام'];
export const GLOBAL_CATEGORIES = ['سياسي', 'اقتصادي', 'تقني', 'عسكري', 'مناخ', 'عام'];
export const TREND_CATEGORY = 'ترند';

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

export function isWorthPublishing(it, { requireStrong = true } = {}) {
  const text = `${String(it.title || '')} ${String(it.description || '')}`;
  if (hasArabic(text)) {
    if (AR_WEAK_PATTERNS.some((re) => re.test(text))) return false;
    return true;
  }
  if (WEAK_PATTERNS.some((re) => re.test(text))) return false;
  if (!requireStrong) return true;
  return STRONG_PATTERNS.some((re) => re.test(text));
}

export async function arabicFallback(it, defaultCategory = 'تقنية عامة') {
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
    enriched.summary = content;
    enriched.content = content;
  } catch (e) {
    log(`تنبيه: تعذرت الترجمة المجانية: ${e.message}`);
    enriched.originalTitle = rawTitle;
    enriched.title = rawTitle;
    enriched.summary = rawContent;
    enriched.content = rawContent;
    enriched._translationFailed = true;
  }
  enriched.category = it.category || defaultCategory;
  return enriched;
}

export async function localFilterAndTranslate(items, { requireStrong = true, defaultCategory = 'تقنية عامة' } = {}) {
  const kept = items.filter((it) => isWorthPublishing(it, { requireStrong }));
  const rejected = items.length - kept.length;
  if (rejected > 0) log(`الفلترة المحلية: رفض ${rejected} عنصراً ضعيفاً (أدلة/مراجعات/رأي).`);
  return Promise.all(kept.map((it) => arabicFallback(it, defaultCategory)));
}

export async function trendsFallback(items) {
  const out = [];
  for (const it of items) {
    const f = await arabicFallback(it);
    if (!f.summary || f.summary === f.title) {
      f.summary = f.title;
      f.content = f.title;
    }
    out.push(f);
    await sleep(150);
  }
  return out;
}

function buildPrompt(items, label, { mode, categories }) {
  const input = items
    .map((it, i) => JSON.stringify({ id: i, title: it.title, description: it.description, pubDate: it.pubDate, traffic: it.approxTraffic || '' }))
    .join('\n');

  const isTrends = mode === 'trends';
  const catList = categories.join('، ');
  const acceptRules = isTrends
    ? `قَبول الترند إذا كان موضوعاً تقنياً أو محلياً أو عالمياً حقيقياً وذا قيمة. رفض فوراً: الترندات الإعلانية والتسويقية والأسماء العشوائية (مثل "هشتاقك بسعر مميز") والكلمات غير المفهومة.`
    : `قَبول إذا كان من النوع التقني الثقيل والجاذب للقارئ العربي مثل: إطلاق هواتف وأجهزة جديدة، مؤتمرات وإعلانات الشركات الكبرى (Apple / Google / Samsung / Microsoft)، تسريبات الأجهزة القادمة، تطورات وتحديثات الذكاء الاصطناعي، استحواذات وصفقات الشركات، أخبار السيارات الذكية والكهربائية (Tesla / Lucid). رفض فوراً إذا كان: مقال رأي شخصي، دليل شراء أو تسوق، مراجعة جهاز بسيط (مروحة، قبعة، ملحق رخيص)، محتوى عام أو ترفيهي، محتوى موسمي (عروض، هدايا، نصائح شراء)، أو خبراً ضعيفاً لا قيمة حقيقية له.`;

  const craft = isTrends
    ? `- أعد صياغة اسم الترند بالعربية بأسلوب صحفي مشوق وجذاب (لا يتجاوز 80 حرفاً).
- اكتب ملخصاً من 3 إلى 4 أسطر يشرح "لماذا يتصدر هذا الموضوع": قصته، سير أحداثه، ولماذا يهتم به الناس، غنياً بالمعلومات الحقيقية من المقطع الإخباري المرافق (traffic تشير لعدد عمليات البحث).`
    : `- أعد صياغة العنوان بالعربية بأسلوب صحفي مشوق وجذاب يحفز القراءة، دقيق وغير مبالغ، ولا يتجاوز 90 حرفاً. مثال: بدلاً من "تحديث تطبيق" اكتب "جوجل تطلق تحديثاً ثورياً لتطبيقاتها.. إليك أبرز الميزات".
- اكتب ملخصاً من 3 إلى 4 أسطر غنياً بالمعلومات الحقيقية المستخرجة من النص (المواصفات، الأسعار، التواريخ، التفاصيل المعلنة) بحيث يكتفي القارئ بفتح البطاقة ليعرف الجوهر.`;

  return `أنت "مدير تحرير" في منصة عربية تقنية احترافية. ستستلم محتوى خام من مصدر: "${label}". عناوينه ومحتواه قد تكون بالإنجليزية أو العربية.

أولاً — الانتقاء (الفلترة):
${acceptRules}

ثانياً — الصياغة الصحفية (للمقبول فقط):
${craft}

قواعد صارمة:
1. كل المخرجات بالعربية حصراً؛ أسماء العلم والشركات والمنتجات الأجنبية (OpenAI، Apple، iPhone، Tesla) تبقى بحروفها اللاتينية.
2. لا تختلق معلومات غير موجودة في النص الأصلي إطلاقاً.
3. أعد JSON على شكل مصفوفة بنفس عدد المدخلات وبنفس المعرفات id، لكل عنصر بالصيغة:
{"id":0,"publish":true,"reason":"سبب موجز للقبول أو الرفض","title":"العنوان العربي","summary":"سطر1\\nسطر2\\nسطر3","category":"${isTrends ? 'ترند' : 'أجهزة'}"}
- للمرفوض: publish=false و reason يوضح السبب، واترك title و summary فارغين.
- التصنيف category من القائمة حصراً: ${catList}
- إن كان عدد المقبولين قليلاً فاكتفِ بهم ولا تحاول حشو الصفحة بمحتوى ضعيف.

المحتوى:
${input}`;
}

export async function editBatch(items, label, { mode = 'news', categories = TECH_CATEGORIES } = {}) {
  if (!items || !items.length) return [];
  const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
  const model = genAI.getGenerativeModel({
    model: process.env.GEMINI_MODEL || 'gemini-2.0-flash',
    generationConfig: { temperature: 0.4, responseMimeType: 'application/json' },
  });

  const prompt = buildPrompt(items, label, { mode, categories });

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
        await sleep(delay);
      }
    }
    throw lastErr;
  }

  async function generateOnce(p) {
    const result = await generateWithRetry(p);
    return extractJsonBlock(result.response.text());
  }

  log(`تحرير ${items.length} عنصراً من "${label}" عبر ${process.env.GEMINI_MODEL || 'gemini-2.0-flash'}...`);
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
        `${prompt}\n\nتذكير صارم أخير: العنوان يجب أن يكون صياغة عربية حقيقية للعنصر المقبول 100% عدا أسماء العلم والشركات، والملخص بالعربية. إن كانت أي استجابة publish=true وعنوانها بالإنجليزية فأعد صياغتها بالعربية قبل الإجابة.`
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
    const finalContent = content || (fallback && fallback.summary) || stripHtml(it.description || '').slice(0, 300);
    if (!hasArabic(finalTitle)) {
      log(`تخطي (عنوان غير عربي بعد الترجمة): ${String(it.title).slice(0, 60)}`);
      continue;
    }
    accepted.push({
      ...it,
      title: finalTitle,
      summary: finalContent,
      content: finalContent,
      category: categories.includes(g.category) ? g.category : categories[0],
      reason: g.reason || '',
      _translationFailed: fallback ? fallback._translationFailed : false,
    });
  }
  return accepted;
}
