import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../services/image_picker_web.dart';
import '../widgets/site_text.dart';
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
                NavigationRailDestination(icon: Icon(Icons.text_fields), label: Text('نصوص الموقع')),
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
              const _SiteTextsTab(),
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
                BottomNavigationBarItem(icon: Icon(Icons.text_fields), label: 'نصوص'),
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

  static const _sections = <_NewsSectionDef>[
    _NewsSectionDef(collection: 'tech_news', label: 'أخبار التقنية', icon: Icons.phone_android, color: Color(0xFF00D4FF)),
    _NewsSectionDef(collection: 'saudi_news', label: 'الأخبار المحلية', icon: Icons.flag, color: Color(0xFF34A853)),
    _NewsSectionDef(collection: 'google_trends', label: 'ترند Google', icon: Icons.trending_up, color: Color(0xFF4285F4)),
    _NewsSectionDef(collection: 'twitter_trends', label: 'ترند X', icon: Icons.alternate_email, color: Color(0xFF1DA1F2)),
    _NewsSectionDef(collection: 'global_news', label: 'نبض عالمي', icon: Icons.public, color: Color(0xFFFBBC05)),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('إدارة الأخبار والترندات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
        const SizedBox(height: 4),
        Text('الأقسام الخمسة تُحدَّث لحظياً من Firestore — الحذف مباشر من المجموعة والتعديل يُحفظ فوراً.',
            style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
        const SizedBox(height: 16),
        for (final s in _sections) _NewsSectionAdmin(section: s),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _NewsSectionDef {
  final String collection;
  final String label;
  final IconData icon;
  final Color color;
  const _NewsSectionDef({required this.collection, required this.label, required this.icon, required this.color});
}

class _NewsSectionAdmin extends StatelessWidget {
  final _NewsSectionDef section;
  const _NewsSectionAdmin({required this.section});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(section.collection).orderBy('date', descending: true).snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: section.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Icon(section.icon, size: 16, color: section.color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(section.label,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: section.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text('${docs.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: section.color)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!snap.hasData)
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
            else if (docs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('لا توجد عناصر في هذا القسم.',
                    style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
              )
            else
              ...docs.map((doc) => _NewsAdminCard(section: section, doc: doc)),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

class _NewsAdminCard extends StatelessWidget {
  final _NewsSectionDef section;
  final QueryDocumentSnapshot<Object?> doc;
  const _NewsAdminCard({required this.section, required this.doc});

  String _fmtDate(dynamic v) {
    DateTime? dt;
    if (v is Timestamp) {
      dt = v.toDate();
    } else if (v is DateTime) {
      dt = v;
    } else {
      final s = v as String? ?? '';
      dt = s.isNotEmpty ? DateTime.tryParse(s) : null;
    }
    if (dt == null) return '';
    final now = DateTime.now();
    final hm = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    if (day == today) return 'اليوم $hm';
    if (day == today.subtract(const Duration(days: 1))) return 'أمس $hm';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $hm';
  }

  Future<void> _edit(BuildContext context) async {
    final data = doc.data() as Map<String, dynamic>;
    final titleCtrl = TextEditingController(text: data['title'] as String? ?? '');
    final summaryCtrl = TextEditingController(text: (data['summary'] as String? ?? data['content'] as String? ?? '').trim());
    final sourceCtrl = TextEditingController(text: data['source'] as String? ?? '');
    final catCtrl = TextEditingController(text: data['category'] as String? ?? '');
    final urlCtrl = TextEditingController(text: (data['url'] as String? ?? data['link'] as String? ?? '').trim());
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الخبر'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder()), maxLines: 2),
                const SizedBox(height: 12),
                TextField(controller: summaryCtrl, decoration: const InputDecoration(labelText: 'الملخص', border: OutlineInputBorder()), maxLines: 4),
                const SizedBox(height: 12),
                TextField(controller: sourceCtrl, decoration: const InputDecoration(labelText: 'المصدر', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'التصنيف', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'رابط المصدر', border: OutlineInputBorder())),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              try {
                await doc.reference.update({
                  'title': titleCtrl.text.trim(),
                  'summary': summaryCtrl.text.trim(),
                  'content': summaryCtrl.text.trim(),
                  'description': summaryCtrl.text.trim(),
                  'source': sourceCtrl.text.trim(),
                  'category': catCtrl.text.trim(),
                  'url': urlCtrl.text.trim(),
                  'link': urlCtrl.text.trim(),
                });
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('خطأ في الحفظ: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('تم حفظ التعديلات'), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الخبر'),
        content: const Text('سيتم مسح هذا الخبر نهائياً من Firestore. هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف نهائياً'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await doc.reference.delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('تم حذف الخبر'), behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الحذف: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] as String? ?? '';
    final summary = (data['summary'] as String? ?? data['content'] as String? ?? '').trim();
    final source = data['source'] as String? ?? '';
    final category = data['category'] as String? ?? '';
    final dateLabel = _fmtDate(data['date'] ?? data['createdAt'] ?? data['publishedAt']);
    final subtitle = [
      if (source.isNotEmpty) source,
      if (category.isNotEmpty) category,
      if (dateLabel.isNotEmpty) dateLabel,
    ].join(' • ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: section.color)),
                  ],
                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(tooltip: 'تعديل', icon: const Icon(Icons.edit, size: 18), onPressed: () => _edit(context)),
            IconButton(tooltip: 'حذف', icon: Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => _delete(context)),
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

class _SiteTextsTab extends StatefulWidget {
  const _SiteTextsTab();
  @override
  State<_SiteTextsTab> createState() => _SiteTextsTabState();
}

class _SiteTextsTabState extends State<_SiteTextsTab> {
  final _docRef = FirebaseFirestore.instance.collection('settings').doc('site_texts');
  final Map<String, TextEditingController> _controllers = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snap = await _docRef.get();
      final data = snap.data() ?? {};
      for (final def in siteTextFieldDefs) {
        final v = data[def.key];
        _controllers[def.key] = TextEditingController(
          text: (v is String && v.trim().isNotEmpty) ? v : def.fallback,
        );
      }
    } catch (_) {
      for (final def in siteTextFieldDefs) {
        _controllers[def.key] = TextEditingController(text: def.fallback);
      }
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    try {
      final map = <String, dynamic>{
        for (final def in siteTextFieldDefs) def.key: _controllers[def.key]!.text.trim(),
      };
      await _docRef.set(map, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('تم حفظ نصوص الصفحة الرئيسية'), behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الحفظ: $e')));
    }
  }

  Future<void> _reset() async {
    try {
      final map = <String, dynamic>{
        for (final def in siteTextFieldDefs) def.key: def.fallback,
      };
      await _docRef.set(map, SetOptions(merge: true));
      for (final def in siteTextFieldDefs) {
        _controllers[def.key]?.text = def.fallback;
      }
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('تمت استعادة النصوص الافتراضية'), behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الاستعادة: $e')));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text('نصوص الصفحة الرئيسية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.restore, size: 16),
              label: const Text('استعادة الافتراضي'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save, size: 16),
              label: const Text('حفظ الكل'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('عدّل أي نص يظهر في الصفحة الرئيسية وسيتم الحفظ مباشرة في Firestore.',
            style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final def in siteTextFieldDefs) ...[
                  TextField(
                    controller: _controllers[def.key],
                    maxLines: def.multiline ? 3 : 1,
                    decoration: InputDecoration(labelText: def.label, border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
