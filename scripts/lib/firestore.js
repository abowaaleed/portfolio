/**
 * تهيئة Firestore، بناء المستندات، الحفظ، إزالة التكرار، والتنظيف.
 */
import admin from 'firebase-admin';
import { log, stripHtml, imageToBase64 } from './core.js';

let db = null;

export function initFirestore(saJson) {
  const sa = JSON.parse(saJson);
  admin.initializeApp({ credential: admin.credential.cert(sa) });
  db = admin.firestore();
  db.settings({ ignoreUndefinedProperties: true });
  log(`Firestore جاهز على مشروع: ${sa.project_id || 'غير معروف'}`);
  return db;
}

export function getDb() {
  return db;
}

export function toTimestamp(d) {
  const dt = d instanceof Date && !isNaN(d) ? d : new Date();
  if (db) return admin.firestore.Timestamp.fromDate(dt);
  return dt.toISOString();
}

export function buildDoc(it, preview = false) {
  const fallbackContent = stripHtml(it.description || '').slice(0, 300) || it.title || '';
  const summary = it.summary || it.content || fallbackContent;
  const base = {
    title: it.title || '',
    summary,
    content: summary,
    description: summary,
    source: it.source || '',
    category: it.category || 'تقنية عامة',
    link: it.url || it.link || '',
    url: it.url || it.link || '',
    publishedAt: it.pubDate || null,
    createdAt: preview ? new Date().toISOString() : admin.firestore.Timestamp.now(),
  };
  base.date = toTimestamp(it.pubDate ? new Date(it.pubDate) : new Date());
  base.originalTitle = it.originalTitle || it.title || '';
  if (it.imageUrl) base.imageUrl = it.imageUrl;
  if (it.imageBase64) base.imageBase64 = it.imageBase64;
  if (it.approxTraffic) base.approxTraffic = it.approxTraffic;
  if (it.reason) base.reason = it.reason;
  return base;
}

export async function saveItemToCollection(collection, it, dryRun, fetchImages) {
  if (fetchImages && it.imageUrl) {
    it.imageBase64 = await imageToBase64(it.imageUrl);
  }
  const doc = buildDoc(it, dryRun);
  if (dryRun) {
    log(`[تجريبي] ${collection}: "${doc.title}" | ${doc.source} | ${doc.category}${doc.imageBase64 ? ' | مع صورة' : ''}`);
    return 'dry-run';
  }
  await db.collection(collection).add(doc);
  return 'saved';
}

export async function findExistingByUrl(collection, url) {
  if (!db) return null;
  const snap = await db.collection(collection).where('url', '==', url).limit(1).get();
  return snap.empty ? null : snap.docs[0];
}

export async function wipeCollection(collection) {
  if (!db) return 0;
  let deleted = 0;
  const snap = await db.collection(collection).get();
  for (const doc of snap.docs) {
    await doc.ref.delete();
    deleted++;
  }
  if (deleted > 0) log(`تم مسح ${deleted} مستنداً من ${collection}.`);
  return deleted;
}

export async function cleanNonArabic(collection, keepUrls = new Set()) {
  if (!db) return 0;
  let deleted = 0;
  const snap = await db.collection(collection).get();
  for (const doc of snap.docs) {
    const d = doc.data();
    const title = String(d.title || '');
    const url = String(d.url || d.link || '');
    if (title && !/[\u0600-\u06FF]/.test(title) && !keepUrls.has(url)) {
      await doc.ref.delete();
      deleted++;
      log(`حذف عنصر غير عربي من ${collection}: ${title.slice(0, 60)}`);
    }
  }
  return deleted;
}

export async function pruneCollection(collection, keep) {
  if (!db) return 0;
  const snap = await db.collection(collection).orderBy('date', 'desc').limit(keep * 2).get();
  if (snap.size <= keep) return 0;
  const docs = snap.docs.slice(keep);
  let deleted = 0;
  for (const doc of docs) {
    await doc.ref.delete();
    deleted++;
  }
  if (deleted > 0) log(`تمت إزالة ${deleted} عنصراً قديماً من ${collection} (الإبقاء على آخر ${keep}).`);
  return deleted;
}

export async function saveBatch(collection, items, { dryRun, fetchImages, dedupe = true, maxPublished }) {
  const savedUrls = new Set();
  const list = (items || []).slice(0, maxPublished);
  let savedCount = 0;
  let skipped = 0;
  for (const it of list) {
    const url = it.url || it.link || '';
    if (dedupe && url) {
      const existing = await findExistingByUrl(collection, url);
      if (existing) {
        skipped++;
        continue;
      }
    }
    try {
      await saveItemToCollection(collection, it, dryRun, fetchImages);
      savedCount++;
      if (url) savedUrls.add(url);
    } catch (e) {
      log(`فشل حفظ في ${collection}: ${url}: ${e.message}`);
    }
  }
  log(`تمت معالجة ${collection}: ${list.length} عنصراً (حفظ ${savedCount}، مكرر/متفاوت ${skipped}).`);
  return savedUrls;
}
