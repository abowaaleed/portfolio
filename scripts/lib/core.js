/**
 * أدوات مشتركة: سجل، جلب، XML/HTML، ترجمة مجانية، استخراج JSON.
 */

export function log(...args) {
  console.log(new Date().toISOString(), ...args);
}

export const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

export async function fetchWithRetry(url, attempts = 3, options = {}) {
  let lastErr;
  for (let i = 1; i <= attempts; i++) {
    try {
      const res = await fetch(url, {
        headers: {
          'User-Agent': options.ua
            || 'Mozilla/5.0 (compatible; PortfolioNewsFetcher/1.0; +https://github.com/abowaaleed/portfolio)',
          Accept: options.accept || 'application/rss+xml, application/xml, text/xml, */*',
        },
        redirect: 'follow',
      });
      if (res.ok) return res;
      lastErr = new Error(`HTTP ${res.status}`);
    } catch (e) {
      lastErr = e;
    }
    await sleep(3000 * i);
  }
  throw lastErr;
}

export function decodeEntities(str) {
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

export function stripHtml(html) {
  return decodeEntities(String(html || '')
    .replace(/<[^>]*>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim());
}

export function hasArabic(text) {
  return /[\u0600-\u06FF]/.test(String(text || ''));
}

export async function translateText(text) {
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

export function extractJsonBlock(text) {
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

export async function imageToBase64(url) {
  try {
    const res = await fetch(url, {
      headers: { 'User-Agent': 'Mozilla/5.0 (compatible; PortfolioNewsFetcher/1.0)' },
      redirect: 'follow',
    });
    if (!res.ok) return null;
    const buf = Buffer.from(await res.arrayBuffer());
    if (buf.length > 500 * 1024) return null;
    const mime = res.headers.get('content-type')?.split(';')[0] || 'image/jpeg';
    return `data:${mime};base64,${buf.toString('base64')}`;
  } catch {
    return null;
  }
}
