/**
 * فلتر المحتوى الصارم (Content Moderation Filter):
 *  - قائمة كلمات محظورة (عربي + إنجليزي) تغطي: الأسلحة، النزاعات المسلحة العنيفة،
 *    الإرهاب والتطرف، العنصرية وخطاب الكراهية، والمحتوى المثير للرأي العام
 *    والأزمات وغير الأخلاقي.
 *  - فحص العنوان والملخص (title, summary, description, content, originalTitle)
 *    قبل الاعتماد وقبل التخزين في Firestore.
 *  - أي عنصر يطابق معيار حظر يُستبعد تلقائياً ولا يُخزَّن.
 */
import { log } from './core.js';

/* تطبيع النص: توحيد الألفات والياء والتاء المربوطة، وحذف التشكيل وعلامات الترقيم */
export function normalizeForModeration(s) {
  return String(s || '')
    .replace(/[أإآٱ]/g, 'ا')
    .replace(/[ىي]/g, 'ي')
    .replace(/ة/g, 'ه')
    .replace(/[\u064B-\u065F\u0640]/g, '')
    .replace(/[^\u0600-\u06FFa-zA-Z0-9\s]/g, ' ')
    .toLowerCase();
}

const escapeRe = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

/* الكلمات المحظورة بالعربية (بالصيغة المطبَّعة بعد التطبيع) */
const AR_BLOCKED = [
  // الأسلحة والنزاعات المسلحة العنيفة
  'قصف', 'غارات', 'قنابل', 'قنبله', 'صواريخ', 'صاروخ', 'مسيرات', 'درون',
  'تفجير', 'انفجار', 'انفجارات', 'متفجرات', 'متفجره', 'عبوه ناسفه',
  'دبابه', 'دبابات', 'مدفعيه', 'ذخائر', 'الغام',
  'قتلى', 'قتيل', 'مقتل', 'مقتول', 'شهداء', 'شهيد', 'مجزره', 'مجازر', 'اباده',
  'حرب', 'حروب', 'حربي', 'حربيه', 'عسكري', 'عسكريه', 'عسكريا', 'جيش', 'جنود',
  'معارك', 'معركه', 'اشتباكات', 'اشتباك', 'مواجهات', 'حصار', 'غزو',
  'اجتياح', 'احتلال', 'نزوح', 'لاجئين', 'لاجئون', 'جرحى', 'مصابين', 'مصابون',
  'قتال', 'استشهاد', 'استشهد', 'عملية عسكريه', 'عمليات عسكريه', 'ضربه جويه',
  'ضربات جويه', 'تسليح', 'سلاح', 'اسلحه', 'مقاتلات', 'مقاتله', 'طياره حربيه',
  'طيارات حربيه', 'هجوم مسلح', 'هجوم ارهابي', 'هجوم عسكري',
  // بؤر الصراع المشهورة
  'غزه', 'رفح',
  // الإرهاب والجماعات المتطرفة
  'ارهاب', 'ارهابي', 'ارهابيين', 'ارهابيه', 'تطرف', 'متطرف', 'متطرفين',
  'متطرفه', 'داعش', 'القاعده', 'طالبان', 'جهاد', 'جهادي', 'جهاديين',
  'خليه ارهابيه', 'مسلح', 'مسلحين', 'مسلحه', 'جماعات مسلحه', 'حوثي',
  'حوثيين', 'بوكو حرام',
  // العنصرية وخطاب الكراهية
  'عنصريه', 'عنصري', 'تمييز', 'كراهيه', 'خطاب الكراهيه', 'ازدراء', 'تحقير',
  'تنمر', 'تشهير', 'دعوه للكراهيه',
  // المحتوى المثير للرأي العام والأزمات وغير الأخلاقي
  'فتنه', 'فوضى', 'انهيار', 'احتجاجات', 'مظاهرات', 'اعتصامات', 'اعتصام',
  'اضراب', 'اضطرابات', 'توترات', 'ازمه', 'ازمات', 'شائعات', 'فضيحه',
  'فضائح', 'اخبار كاذبه', 'تضليل', 'تحريض', 'دعايه',
];

/* الكلمات المحظورة بالإنجليزية (أنماط RegExp مع حدود الكلمات) */
const EN_BLOCKED = [
  '\\bwar(?:s|fare|ring)?\\b',
  '\\bmissiles?\\b',
  '\\bbombs?(?:ing|er)?\\b',
  '\\bexplos(?:ion|ive)s?\\b',
  '\\bairstrikes?\\b',
  '\\bair strikes?\\b',
  '\\bmilitar',
  '\\btroops?\\b',
  '\\bsoldiers?\\b',
  '\\bweapons?\\b',
  '\\bweaponiz',
  '\\bartillery\\b',
  '(?<!think )\\btanks?\\b',
  '\\bdrone strikes?\\b',
  '\\bcasualt(?:y|ies)\\b',
  '\\bdeaths?\\b',
  '\\bkilled\\b',
  '\\bkillings?\\b',
  '\\bslaughter(?:ed|ing)?\\b',
  '\\bmassacres?\\b',
  '\\bgenocid(?:e|es)\\b',
  '\\bsieges?\\b',
  '\\binvasions?\\b',
  '\\boccupations?\\b',
  '\\barmed\\b',
  '\\bterror(?:ism|ist|ists)?\\b',
  '\\bextremis(?:t|ts|m)\\b',
  '\\bjihads?\\b',
  '\\bmilitia(?:s)?\\b',
  '\\bmilitants?\\b',
  '\\bguerrillas?\\b',
  '\\binsurgen(?:t|cy|ts)\\b',
  '\\bhostages?\\b',
  '\\bcoups?\\b',
  '\\brefugees?\\b',
  '\\bdisplaced\\b',
  '\\bevacuat(?:ion|e|ed|es|ing)s?\\b',
  '\\bracis(?:m|t|ts)\\b',
  '\\bhate(?:ful)?\\b',
  '\\bhate speech\\b',
  '\\bdiscriminat(?:ion|ory|e|ed|es|ing)s?\\b',
  '\\bxenophob(?:a|e|ia|ic)\\b',
  '\\bintoleran(?:ce|t)\\b',
  '\\bsanctions?\\b',
  '\\bethnic cleansing\\b',
  '\\briots?\\b',
  '\\bunrest\\b',
  '\\buprising(?:s)?\\b',
  '\\bprotests?(?:ers)?\\b',
  '\\bcrises?\\b',
  '\\bcollapse(?:s|d)?\\b',
  '\\bhostilities?\\b',
];

const AR_PATTERNS = AR_BLOCKED.map((term) => ({
  label: `عربي: ${term}`,
  re: new RegExp(`(?<![\\p{L}\\p{N}])${escapeRe(term)}(?![\\p{L}\\p{N}])`, 'u'),
}));

const EN_PATTERNS = EN_BLOCKED.map((term) => ({
  label: `EN: ${(term.match(/[a-z]+/i) || [''])[0]}`,
  re: new RegExp(term, 'i'),
}));

export const MODERATION_PATTERNS = [...AR_PATTERNS, ...EN_PATTERNS];

/**
 * يُرجع سبب الحظر (أول كلمة مطابقة) أو null إذا كان المحتوى سليماً.
 * يفحص العنوان والملخص والوصف والمحتوى والعنوان الأصلي.
 */
export function blockedReason(it) {
  const text = [it.title, it.summary, it.description, it.content, it.originalTitle]
    .filter((v) => v != null && String(v).trim() !== '')
    .map(normalizeForModeration)
    .join(' ');
  if (!text) return null;
  for (const { label, re } of MODERATION_PATTERNS) {
    if (re.test(text)) return label;
  }
  return null;
}

export function isBlockedContent(it) {
  return blockedReason(it) != null;
}

/** يفلتر قائمة عناصر ويعيد { kept, removed } مع تسجيل كل عنصر محظور. */
export function filterBlocked(items) {
  const kept = [];
  let removed = 0;
  for (const it of items || []) {
    const label = blockedReason(it);
    if (label) {
      removed++;
      log(`حظر المحتوى: "${String(it.title || it.originalTitle || '').slice(0, 70)}" ← ${label}`);
    } else {
      kept.push(it);
    }
  }
  return { kept, removed };
}

/**
 * تعليمات الحظر الصارمة المدرجة في System Prompt الخاص بـ Gemini/المنسق
 * لاستبعاد الفئات المحظورة والاكتفاء بالعناصر التقنية والتنموية الخفيفة والمفيدة.
 */
export const MODERATION_RULES = `حظر المحتوى (سياسة صارمة لا استثناء فيها):
استبعد فوراً وأرفض أي عنصر يندرج تحت الفئات التالية:
- الأخبار المتعلقة بالأسلحة أو النزاعات المسلحة العنيفة (قصف، غارات، صواريخ، انفجارات، معارك، حروب، حصار، غزو، نزوح، لاجئون، قتلى، جرحى، مجازر).
- المحتوى المحرض على العنصرية أو التمييز أو خطاب الكراهية.
- الأخبار المرتبطة بالإرهاب أو الجماعات المتطرفة أو العنف.
- أي محتوى معادٍ، أو مثير للرأي العام والأزمات، أو غير أخلاقي (احتجاجات، اضطرابات، فضائح، أخبار كاذبة، تضليل).
عند مصادفة أي عنصر من هذه الفئات: أعد publish=false فوراً دون معالجة أو تلخيص لمحتواه، واجعل reason="محتوى محظور (سياسة المحتوى)"، واترك title و summary فارغين. لا تختلق بديلاً ولا تحشو الصفحة؛ القسم سيمتلئ تلقائياً بالعناصر التقنية والتنموية الخفيفة والمفيدة المقبولة.`;
