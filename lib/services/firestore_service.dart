import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_item.dart';
import '../models/blog_post.dart';
import '../models/news_item.dart';
import '../models/tutorial.dart';
import '../models/feedback_item.dart';

FirebaseFirestore get _db {
  try {
    return FirebaseFirestore.instance;
  } catch (_) {
    throw Exception('Firestore not initialized');
  }
}

class FirestoreService {
  static Future<List<AppItem>> getApps() async {
    final snap = await _db.collection('apps').get();
    final docs = [...snap.docs];
    docs.sort((a, b) {
      final pa = (a.data())['isPinned'] as bool? ?? false;
      final pb = (b.data())['isPinned'] as bool? ?? false;
      return (pb ? 1 : 0).compareTo(pa ? 1 : 0);
    });
    return docs.map((d) => AppItem.fromMap({...d.data(), 'id': d.id})).toList();
  }

  static Future<void> addApp(AppItem app) async {
    await _db.collection('apps').add(app.toMap());
  }

  static Future<void> updateApp(String id, Map<String, dynamic> data) async {
    await _db.collection('apps').doc(id).update(data);
  }

  static Future<void> deleteApp(String id) async {
    await _db.collection('apps').doc(id).delete();
  }

  static Future<void> incrementAppClick(String id) async {
    await _db.collection('apps').doc(id).update({'clickCount': FieldValue.increment(1)});
  }

  static Future<List<BlogPost>> getBlogPosts() async {
    final snap = await _db.collection('blog').get();
    final docs = [...snap.docs];
    docs.sort((a, b) {
      final da = a.data()['date'];
      final db = b.data()['date'];
      final ad = da is Timestamp ? da.toDate() : da is DateTime ? da : DateTime.fromMillisecondsSinceEpoch(0);
      final bd = db is Timestamp ? db.toDate() : db is DateTime ? db : DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return docs.map((d) {
      final data = d.data();
      return BlogPost(
        id: d.id,
        title: data['title'] as String? ?? '',
        excerpt: data['excerpt'] as String? ?? '',
        content: data['content'] as String? ?? '',
        imageUrl: data['imageUrl'] as String? ?? '',
        category: data['category'] as String? ?? '',
        readTime: data['readTime'] as int? ?? 3,
        date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        slug: data['slug'] as String? ?? '',
      );
    }).toList();
  }

  static Future<void> addBlogPost(BlogPost post) async {
    await _db.collection('blog').add({
      'title': post.title,
      'excerpt': post.excerpt,
      'content': post.content,
      'imageUrl': post.imageUrl,
      'category': post.category,
      'readTime': post.readTime,
      'date': post.date,
      'slug': post.slug,
      'views': 0,
    });
  }

  static Future<void> deleteBlogPost(String id) async {
    await _db.collection('blog').doc(id).delete();
  }

  static Future<List<Tutorial>> getTutorials() async {
    final snap = await _db.collection('tutorials').get();
    return snap.docs.map((d) {
      final data = d.data();
      return Tutorial(
        id: d.id,
        title: data['title'] as String? ?? '',
        thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
        category: data['category'] as String? ?? '',
        readTime: data['readTime'] as int? ?? 5,
        url: data['url'] as String? ?? '',
      );
    }).toList();
  }

  static Future<void> addTutorial(Tutorial t) async {
    await _db.collection('tutorials').add({
      'title': t.title,
      'thumbnailUrl': t.thumbnailUrl,
      'category': t.category,
      'readTime': t.readTime,
      'url': t.url,
      'views': 0,
    });
  }

  static Future<void> deleteTutorial(String id) async {
    await _db.collection('tutorials').doc(id).delete();
  }

  static Future<List<NewsItem>> getNews() async {
    final snap = await _db.collection('news').get();
    final docs = [...snap.docs];
    docs.sort((a, b) {
      final da = a.data()['date'];
      final db = b.data()['date'];
      final ad = da is Timestamp ? da.toDate() : da is DateTime ? da : DateTime.fromMillisecondsSinceEpoch(0);
      final bd = db is Timestamp ? db.toDate() : db is DateTime ? db : DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return docs.map((d) {
      final data = d.data();
      return NewsItem(
        id: d.id,
        title: data['title'] as String? ?? '',
        source: data['source'] as String? ?? '',
        date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        url: data['url'] as String? ?? '',
      );
    }).toList();
  }

  static Future<void> addNews(NewsItem n) async {
    await _db.collection('news').add({'title': n.title, 'source': n.source, 'date': n.date, 'url': n.url, 'views': 0});
  }

  static Future<void> deleteNews(String id) async {
    await _db.collection('news').doc(id).delete();
  }

  static Future<List<FeedbackItem>> getFeedback() async {
    final snap = await _db.collection('feedback').get();
    final docs = [...snap.docs];
    docs.sort((a, b) {
      final da = a.data()['date'];
      final db = b.data()['date'];
      final ad = da is Timestamp ? da.toDate() : da is DateTime ? da : DateTime.fromMillisecondsSinceEpoch(0);
      final bd = db is Timestamp ? db.toDate() : db is DateTime ? db : DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return docs.map((d) {
      final data = d.data();
      return FeedbackItem(
        id: d.id,
        name: data['name'] as String? ?? '',
        comment: data['comment'] as String? ?? '',
        rating: (data['rating'] as num?)?.toDouble() ?? 0,
        date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        approved: data['approved'] as bool? ?? false,
      );
    }).toList();
  }

  static Future<void> addFeedback(FeedbackItem f) async {
    await _db.collection('feedback').add({
      'name': f.name,
      'comment': f.comment,
      'rating': f.rating,
      'date': f.date,
      'approved': false,
    });
  }

  static Future<void> approveFeedback(String id) async {
    await _db.collection('feedback').doc(id).update({'approved': true});
  }

  static Future<void> deleteFeedback(String id) async {
    await _db.collection('feedback').doc(id).delete();
  }

  static Future<void> trackPageView() async {
    try {
      final today = DateTime.now();
      final dayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final ref = _db.collection('analytics').doc(dayStr);
      await ref.set({'views': FieldValue.increment(1), 'date': today}, SetOptions(merge: true));
    } catch (_) {}
  }

  static Future<Map<String, int>> getAnalytics() async {
    try {
      final snap = await _db.collection('analytics').get();
      final docs = [...snap.docs];
      docs.sort((a, b) {
        final da = a.data()['date'];
        final db = b.data()['date'];
        final ad = da is Timestamp ? da.toDate() : da is DateTime ? da : DateTime.fromMillisecondsSinceEpoch(0);
        final bd = db is Timestamp ? db.toDate() : db is DateTime ? db : DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
      final limited = docs.length > 30 ? docs.sublist(0, 30) : docs;
      int total = 0;
      for (final d in limited) {
        total += (d.data()['views'] as num?)?.toInt() ?? 0;
      }
      return {'totalViews': total, 'daysCount': limited.length};
    } catch (_) {
      return {'totalViews': 0, 'daysCount': 0};
    }
  }
}
