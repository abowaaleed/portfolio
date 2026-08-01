import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../services/image_picker_web.dart';
import 'admin_login.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _tab = 0;
  Map<String, int> _stats = {'totalViews': 0, 'daysCount': 0};
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    _stats = await FirestoreService.getAnalytics();
    if (mounted) setState(() => _loadingStats = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) return const AdminLogin();
    if (!auth.isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('ليس لديك صلاحية الدخول', style: TextStyle(fontSize: 18, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => auth.signOut(), child: const Text('تسجيل خروج')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة التحكم — ${AppInfo.version}'),
        actions: [
          Consumer<ThemeProvider>(builder: (_, tp, __) => IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => tp.toggleTheme(),
          )),
          PopupMenuButton(itemBuilder: (_) => [
            const PopupMenuItem(value: 'logout', child: Text('تسجيل خروج')),
          ], onSelected: (v) => auth.signOut(), icon: Icon(Icons.account_circle, color: AppColors.accent)),
        ],
      ),
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width > 768)
            NavigationRail(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('الإحصائيات')),
                NavigationRailDestination(icon: Icon(Icons.apps), label: Text('التطبيقات')),
                NavigationRailDestination(icon: Icon(Icons.article), label: Text('المدونة')),
                NavigationRailDestination(icon: Icon(Icons.school), label: Text('الشروحات')),
                NavigationRailDestination(icon: Icon(Icons.newspaper), label: Text('الأخبار')),
                NavigationRailDestination(icon: Icon(Icons.share), label: Text('التواصل')),
                NavigationRailDestination(icon: Icon(Icons.feedback), label: Text('التعليقات')),
                NavigationRailDestination(icon: Icon(Icons.palette), label: Text('الملف الشخصي')),
              ],
            ),
          Expanded(
            child: [
              _StatsTab(stats: _stats, loading: _loadingStats),
              const _AppsTab(),
              const _BlogTab(),
              const _TutorialsTab(),
              const _NewsTab(),
              const _SocialTab(),
              const _FeedbackTab(),
              const _ProfileTab(),
            ][_tab],
          ),
        ],
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width <= 768
          ? BottomNavigationBar(
              currentIndex: _tab,
              onTap: (i) => setState(() => _tab = i),
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'إحصائيات'),
                BottomNavigationBarItem(icon: Icon(Icons.apps), label: 'تطبيقات'),
                BottomNavigationBarItem(icon: Icon(Icons.article), label: 'مدونة'),
                BottomNavigationBarItem(icon: Icon(Icons.school), label: 'شروحات'),
                BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'أخبار'),
                BottomNavigationBarItem(icon: Icon(Icons.share), label: 'تواصل'),
                BottomNavigationBarItem(icon: Icon(Icons.feedback), label: 'تعليقات'),
                BottomNavigationBarItem(icon: Icon(Icons.palette), label: 'ملفي'),
              ],
            )
          : null,
    );
  }
}

class _StatsTab extends StatelessWidget {
  final Map<String, int> stats;
  final bool loading;

  const _StatsTab({required this.stats, required this.loading});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (loading) return const Center(child: CircularProgressIndicator());

    return GridView.count(
      padding: const EdgeInsets.all(24),
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _StatCard(label: 'إجمالي الزيارات', value: '${stats['totalViews']}', icon: Icons.visibility, color: AppColors.accent, isDark: isDark),
        _StatCard(label: 'أيام مسجلة', value: '${stats['daysCount']}', icon: Icons.calendar_today, color: AppColors.accentPurple, isDark: isDark),
        _StatCard(label: 'متوسط يومي', value: stats['daysCount'] != 0 ? '${(stats['totalViews']! / stats['daysCount']!).toStringAsFixed(0)}' : '0', icon: Icons.trending_up, color: AppColors.success, isDark: isDark),
        _StatCard(label: 'حالة Firebase', value: 'نشط', icon: Icons.check_circle, color: AppColors.success, isDark: isDark),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
            Text(label, style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
          ],
        ),
      ),
    );
  }
}

class _AppsTab extends StatelessWidget {
  const _AppsTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('apps').snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final apps = snap.data!.docs;
        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Text('التطبيقات (${apps.length})', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showAppEditor(context, null),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('إضافة تطبيق'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...apps.map((doc) {
                final data = doc.data();
                return Card(
                  child: ListTile(
                    title: Text(data['name'] as String? ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
                    subtitle: Text('نقرات: ${data['clickCount'] ?? 0} • ${data['status'] ?? 'published'}', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showAppEditor(context, doc)),
                        IconButton(icon: Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () async {
                          await FirebaseFirestore.instance.collection('apps').doc(doc.id).delete();
                        }),
                      ],
                    ),
                  ),
                );
              }),
              if (apps.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text('لا توجد تطبيقات بعد. أضف أول تطبيق!', style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary))),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAppEditor(BuildContext context, dynamic doc) {
    final data = doc?.data() as Map<String, dynamic>?;
    final nameCtrl = TextEditingController(text: data?['name'] as String? ?? '');
    final descCtrl = TextEditingController(text: data?['description'] as String? ?? '');
    final urlCtrl = TextEditingController(text: data?['url'] as String? ?? '');
    final iconUrlCtrl = TextEditingController(text: data?['iconUrl'] as String? ?? '');
    String? imageBase64 = data?['imageBase64'] as String?;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: Text(doc != null ? 'تعديل التطبيق' : 'إضافة تطبيق جديد'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (imageBase64 != null)
                    Container(
                      height: 100, width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(image: MemoryImage(base64Decode(imageBase64!.split(',').last)), fit: BoxFit.cover),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () async {
                      final b64 = await pickImageAsBase64();
                      if (b64 != null) { imageBase64 = b64; setDState(() {}); }
                    },
                    icon: const Icon(Icons.image, size: 18),
                    label: Text(imageBase64 != null ? 'تغيير الصورة' : 'إضافة صورة'),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم التطبيق', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'الوصف', border: OutlineInputBorder()), maxLines: 3),
                  const SizedBox(height: 12),
                  TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'الرابط', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: iconUrlCtrl, decoration: const InputDecoration(labelText: 'رمز الأيقونة (اختياري)', hintText: 'picture_as_pdf', border: OutlineInputBorder())),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final map = <String, dynamic>{
                    'name': nameCtrl.text, 'description': descCtrl.text, 'url': urlCtrl.text,
                    'iconUrl': iconUrlCtrl.text.isEmpty ? 'picture_as_pdf' : iconUrlCtrl.text,
                    'status': data?['status'] ?? 'published', 'clickCount': data?['clickCount'] ?? 0, 'isPinned': data?['isPinned'] ?? false,
                  };
                  if (imageBase64 != null) map['imageBase64'] = imageBase64;
                  if (doc != null) {
                    await doc.reference.update(map);
                  } else {
                    map['status'] = 'published'; map['clickCount'] = 0; map['isPinned'] = false;
                    await FirebaseFirestore.instance.collection('apps').add(map);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('خطأ في الحفظ: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black),
              child: Text(doc != null ? 'حفظ' : 'إضافة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlogTab extends StatelessWidget {
  const _BlogTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('blog').orderBy('date', descending: true).snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final posts = snap.data!.docs;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Text('التدوينات (${posts.length})', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showBlogEditor(context, null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة تدوينة'),
                ),
              ],
            ),
            ...posts.map((doc) {
              final data = doc.data();
              return Card(child: ListTile(
                title: Text(data['title'] as String? ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
                subtitle: Text('مشاهدات: ${data['views'] ?? 0} • ${data['category'] ?? ''}', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
                trailing: IconButton(icon: Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () async {
                  await FirebaseFirestore.instance.collection('blog').doc(doc.id).delete();
                }),
              ));
            }),
          ],
        );
      },
    );
  }

  void _showBlogEditor(BuildContext context, dynamic doc) {
    final d = doc?.data() as Map<String, dynamic>?;
    final titleCtrl = TextEditingController(text: d?['title'] as String? ?? '');
    final excerptCtrl = TextEditingController(text: d?['excerpt'] as String? ?? '');
    final contentCtrl = TextEditingController(text: d?['content'] as String? ?? '');
    final catCtrl = TextEditingController(text: d?['category'] as String? ?? 'عام');
    final readCtrl = TextEditingController(text: (d?['readTime'] as num? ?? 3).toString());
    String? imageBase64 = d?['imageBase64'] as String?;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: Text(doc != null ? 'تعديل تدوينة' : 'إضافة تدوينة'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (imageBase64 != null)
                    Container(
                      height: 100, width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(image: MemoryImage(base64Decode(imageBase64!.split(',').last)), fit: BoxFit.cover),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      final b64 = await pickImageAsBase64();
                      if (b64 != null) { imageBase64 = b64; setDState(() {}); }
                    },
                    icon: const Icon(Icons.image, size: 18),
                    label: Text(imageBase64 != null ? 'تغيير الصورة' : 'إضافة صورة'),
                  ),
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'التصنيف', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: excerptCtrl, decoration: const InputDecoration(labelText: 'المقدمة', border: OutlineInputBorder()), maxLines: 2),
                  const SizedBox(height: 12),
                  TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: 'المحتوى', border: OutlineInputBorder()), maxLines: 5),
                  const SizedBox(height: 12),
                  TextField(controller: readCtrl, decoration: const InputDecoration(labelText: 'وقت القراءة (دقائق)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final map = <String, dynamic>{
                    'title': titleCtrl.text, 'excerpt': excerptCtrl.text, 'content': contentCtrl.text,
                    'category': catCtrl.text, 'readTime': int.tryParse(readCtrl.text) ?? 3, 'date': DateTime.now(), 'views': d?['views'] ?? 0,
                  };
                  if (imageBase64 != null) map['imageBase64'] = imageBase64;
                  if (doc != null) {
                    await doc.reference.update(map);
                  } else {
                    map['imageUrl'] = ''; map['slug'] = ''; map['views'] = 0;
                    await FirebaseFirestore.instance.collection('blog').add(map);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('خطأ في الحفظ: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black),
              child: Text(doc != null ? 'حفظ' : 'إضافة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialsTab extends StatelessWidget {
  const _TutorialsTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('tutorials').snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final tutorials = snap.data!.docs;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Text('الشروحات (${tutorials.length})', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
              const Spacer(),
              ElevatedButton.icon(onPressed: () => _showTutorialEditor(context, null), icon: const Icon(Icons.add, size: 18), label: const Text('إضافة شرح')),
            ]),
            ...tutorials.map((doc) {
              final data = doc.data();
              return Card(child: ListTile(
                title: Text(data['title'] as String? ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
                subtitle: Text('مشاهدات: ${data['views'] ?? 0} • ${data['category'] ?? ''}', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
                trailing: IconButton(icon: Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () async {
                  await FirebaseFirestore.instance.collection('tutorials').doc(doc.id).delete();
                }),
              ));
            }),
          ],
        );
      },
    );
  }

  void _showTutorialEditor(BuildContext context, dynamic doc) {
    final d = doc?.data() as Map<String, dynamic>?;
    final titleCtrl = TextEditingController(text: d?['title'] as String? ?? '');
    final catCtrl = TextEditingController(text: d?['category'] as String? ?? '');
    final readCtrl = TextEditingController(text: (d?['readTime'] as num? ?? 5).toString());
    final urlCtrl = TextEditingController(text: d?['url'] as String? ?? '');
    String? imageBase64 = d?['imageBase64'] as String?;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: Text(doc != null ? 'تعديل شرح' : 'إضافة شرح'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (imageBase64 != null)
                    Container(
                      height: 100, width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(image: MemoryImage(base64Decode(imageBase64!.split(',').last)), fit: BoxFit.cover),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      final b64 = await pickImageAsBase64();
                      if (b64 != null) { imageBase64 = b64; setDState(() {}); }
                    },
                    icon: const Icon(Icons.image, size: 18),
                    label: Text(imageBase64 != null ? 'تغيير الصورة' : 'إضافة صورة'),
                  ),
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'التصنيف', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'الرابط', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: readCtrl, decoration: const InputDecoration(labelText: 'وقت القراءة (دقائق)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final map = <String, dynamic>{
                    'title': titleCtrl.text, 'category': catCtrl.text, 'url': urlCtrl.text,
                    'readTime': int.tryParse(readCtrl.text) ?? 5, 'views': d?['views'] ?? 0,
                  };
                  if (imageBase64 != null) map['imageBase64'] = imageBase64;
                  if (doc != null) {
                    await doc.reference.update(map);
                  } else {
                    map['thumbnailUrl'] = ''; map['views'] = 0;
                    await FirebaseFirestore.instance.collection('tutorials').add(map);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('خطأ في الحفظ: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black),
              child: Text(doc != null ? 'حفظ' : 'إضافة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsTab extends StatelessWidget {
  const _NewsTab();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('news').orderBy('date', descending: true).snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final news = snap.data!.docs;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Text('الأخبار (${news.length})', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
              const Spacer(),
              ElevatedButton.icon(onPressed: () => _showNewsEditor(context, null), icon: const Icon(Icons.add, size: 18), label: const Text('إضافة خبر')),
            ]),
            ...news.map((doc) {
              final data = doc.data();
              return Card(child: ListTile(
                title: Text(data['title'] as String? ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
                subtitle: Text(data['source'] as String? ?? '', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                trailing: IconButton(icon: Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () async {
                  await FirebaseFirestore.instance.collection('news').doc(doc.id).delete();
                }),
              ));
            }),
          ],
        );
      },
    );
  }

  void _showNewsEditor(BuildContext context, dynamic doc) {
    final data = doc?.data() as Map<String, dynamic>?;
    final titleCtrl = TextEditingController(text: data?['title'] as String? ?? '');
    final contentCtrl = TextEditingController(text: data?['content'] as String? ?? '');
    final sourceCtrl = TextEditingController(text: data?['source'] as String? ?? '');
    final urlCtrl = TextEditingController(text: data?['url'] as String? ?? '');
    String? imageBase64 = data?['imageBase64'] as String?;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: Text(doc != null ? 'تعديل خبر' : 'إضافة خبر'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (imageBase64 != null)
                    Container(
                      height: 100, width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(image: MemoryImage(base64Decode(imageBase64!.split(',').last)), fit: BoxFit.cover),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      final b64 = await pickImageAsBase64();
                      if (b64 != null) { imageBase64 = b64; setDState(() {}); }
                    },
                    icon: const Icon(Icons.image, size: 18),
                    label: Text(imageBase64 != null ? 'تغيير الصورة' : 'إضافة صورة'),
                  ),
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'عنوان الخبر', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: 'نص الخبر', border: OutlineInputBorder()), maxLines: 4),
                  const SizedBox(height: 12),
                  TextField(controller: sourceCtrl, decoration: const InputDecoration(labelText: 'المصدر', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'رابط المصدر (اختياري)', border: OutlineInputBorder())),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final map = <String, dynamic>{
                    'title': titleCtrl.text, 'content': contentCtrl.text, 'source': sourceCtrl.text,
                    'url': urlCtrl.text, 'date': DateTime.now(), 'views': data?['views'] ?? 0,
                  };
                  if (imageBase64 != null) map['imageBase64'] = imageBase64;
                  if (doc != null) {
                    await doc.reference.update(map);
                  } else {
                    await FirebaseFirestore.instance.collection('news').add(map);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('خطأ في الحفظ: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black),
              child: Text(doc != null ? 'حفظ' : 'إضافة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialTab extends StatelessWidget {
  const _SocialTab();

  static const _platformIcons = {
    'x-twitter': Icons.alternate_email,
    'github': Icons.code,
    'telegram': Icons.send,
    'instagram': Icons.camera_alt_outlined,
    'snapchat': Icons.star,
    'youtube': Icons.play_circle_filled,
    'linkedin': Icons.business_center,
    'tiktok': Icons.music_note,
    'whatsapp': Icons.chat,
    'website': Icons.language,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('social_links').snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final links = snap.data!.docs;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Text('وسائل التواصل (${links.length})', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
              const Spacer(),
              ElevatedButton.icon(onPressed: () => _showEditor(context, null), icon: const Icon(Icons.add, size: 18), label: const Text('إضافة رابط')),
            ]),
            ...links.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final iconName = data['iconName'] as String? ?? 'link';
              return Card(child: ListTile(
                leading: Icon(_platformIcons[iconName] ?? Icons.link, color: AppColors.accent),
                title: Text(data['name'] as String? ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
                subtitle: Text(data['url'] as String? ?? '', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showEditor(context, doc)),
                    IconButton(icon: Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () async {
                      await FirebaseFirestore.instance.collection('social_links').doc(doc.id).delete();
                    }),
                  ],
                ),
              ));
            }),
          ],
        );
      },
    );
  }

  void _showEditor(BuildContext context, dynamic doc) {
    final data = doc != null ? doc.data() as Map<String, dynamic> : null;
    final nameCtrl = TextEditingController(text: data?['name'] as String? ?? '');
    final urlCtrl = TextEditingController(text: data?['url'] as String? ?? '');
    final iconCtrl = TextEditingController(text: data?['iconName'] as String? ?? '');
    final orderCtrl = TextEditingController(text: (data?['order'] as num? ?? 0).toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(doc != null ? 'تعديل رابط' : 'إضافة رابط'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم المنصة', hintText: 'مثال: تويتر', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'الرابط', hintText: 'https://...', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: iconCtrl, decoration: const InputDecoration(labelText: 'رمز الأيقونة', hintText: 'x-twitter, instagram, youtube...', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              Text('الأيقونات المدعومة: x-twitter, github, telegram, instagram, snapchat, youtube, linkedin, tiktok, whatsapp, website', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              TextField(controller: orderCtrl, decoration: const InputDecoration(labelText: 'الترتيب', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final map = {'name': nameCtrl.text, 'url': urlCtrl.text, 'iconName': iconCtrl.text, 'order': int.tryParse(orderCtrl.text) ?? 0};
              if (doc != null) {
                await doc.reference.update(map);
              } else {
                await FirebaseFirestore.instance.collection('social_links').add(map);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black),
            child: Text(doc != null ? 'حفظ' : 'إضافة'),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab();
  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final _docRef = FirebaseFirestore.instance.collection('settings').doc('profile');

  Future<void> _pickImage(String field) async {
    final b64 = await pickImageAsBase64();
    if (b64 != null) {
      await _docRef.set({field: b64}, SetOptions(merge: true));
    }
  }

  Future<void> _removeImage(String field) async {
    await _docRef.update({field: FieldValue.delete()});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<DocumentSnapshot>(
      stream: _docRef.snapshots(),
      builder: (ctx, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final profImg = data?['profileImageBase64'] as String?;
        final bgImg = data?['backgroundImageBase64'] as String?;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('الملف الشخصي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الصورة الرمزية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
                    const SizedBox(height: 12),
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                            backgroundImage: profImg != null ? MemoryImage(base64Decode(profImg.split(',').last)) : null,
                            child: profImg == null ? const Icon(Icons.person, size: 40, color: AppColors.accent) : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _pickImage('profileImageBase64'),
                                icon: const Icon(Icons.image, size: 18),
                                label: const Text('رفع صورة'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black),
                              ),
                              if (profImg != null) ...[
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _removeImage('profileImageBase64'),
                                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                  label: const Text('حذف', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('خلفية الصفحة الرئيسية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
                    const SizedBox(height: 12),
                    if (bgImg != null)
                      Container(
                        height: 120, width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(image: MemoryImage(base64Decode(bgImg.split(',').last)), fit: BoxFit.cover),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickImage('backgroundImageBase64'),
                          icon: const Icon(Icons.image, size: 18),
                          label: Text(bgImg != null ? 'تغيير الخلفية' : 'إضافة خلفية'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black),
                        ),
                        if (bgImg != null) ...[
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _removeImage('backgroundImageBase64'),
                            icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                            label: const Text('حذف', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FeedbackTab extends StatelessWidget {
  const _FeedbackTab();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('feedback').orderBy('date', descending: true).snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final feedbacks = snap.data!.docs;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('التعليقات (${feedbacks.length})', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
            ...feedbacks.map((doc) {
              final data = doc.data();
              final approved = data['approved'] as bool? ?? false;
              return Card(child: ListTile(
                leading: Icon(approved ? Icons.check_circle : Icons.pending, color: approved ? AppColors.success : AppColors.warning),
                title: Text(data['comment'] as String? ?? '', style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary)),
                subtitle: Text(data['name'] as String? ?? 'زائر', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!approved)
                      IconButton(icon: Icon(Icons.check, size: 18, color: AppColors.success), onPressed: () async {
                        await FirebaseFirestore.instance.collection('feedback').doc(doc.id).update({'approved': true});
                      }),
                    IconButton(icon: Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () async {
                      await FirebaseFirestore.instance.collection('feedback').doc(doc.id).delete();
                    }),
                  ],
                ),
              ));
            }),
          ],
        );
      },
    );
  }
}
