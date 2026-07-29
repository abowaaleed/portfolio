import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
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
        title: const Text('لوحة التحكم'),
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
                NavigationRailDestination(icon: Icon(Icons.feedback), label: Text('التعليقات')),
              ],
            ),
          Expanded(
            child: [
              _StatsTab(stats: _stats, loading: _loadingStats),
              const _AppsTab(),
              const _BlogTab(),
              const _TutorialsTab(),
              const _NewsTab(),
              const _FeedbackTab(),
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
                BottomNavigationBarItem(icon: Icon(Icons.feedback), label: 'تعليقات'),
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
    final nameCtrl = TextEditingController(text: doc != null ? doc.data()['name'] as String? ?? '' : '');
    final descCtrl = TextEditingController(text: doc != null ? doc.data()['description'] as String? ?? '' : '');
    final urlCtrl = TextEditingController(text: doc != null ? doc.data()['url'] as String? ?? '' : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(doc != null ? 'تعديل التطبيق' : 'إضافة تطبيق جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم التطبيق', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'الوصف', border: OutlineInputBorder()), maxLines: 3),
            const SizedBox(height: 12),
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'الرابط', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (doc != null) {
                await doc.reference.update({'name': nameCtrl.text, 'description': descCtrl.text, 'url': urlCtrl.text});
              } else {
                await FirebaseFirestore.instance.collection('apps').add({
                  'name': nameCtrl.text, 'description': descCtrl.text, 'url': urlCtrl.text,
                  'iconUrl': 'picture_as_pdf', 'status': 'published', 'clickCount': 0, 'isPinned': false,
                });
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
    final titleCtrl = TextEditingController(text: doc?.data()['title'] ?? '');
    final excerptCtrl = TextEditingController(text: doc?.data()['excerpt'] ?? '');
    final contentCtrl = TextEditingController(text: doc?.data()['content'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(doc != null ? 'تعديل تدوينة' : 'إضافة تدوينة'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: excerptCtrl, decoration: const InputDecoration(labelText: 'المقدمة', border: OutlineInputBorder()), maxLines: 2),
              const SizedBox(height: 12),
              TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: 'المحتوى', border: OutlineInputBorder()), maxLines: 5),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (doc != null) {
                await doc.reference.update({'title': titleCtrl.text, 'excerpt': excerptCtrl.text, 'content': contentCtrl.text});
              } else {
                await FirebaseFirestore.instance.collection('blog').add({
                  'title': titleCtrl.text, 'excerpt': excerptCtrl.text, 'content': contentCtrl.text,
                  'imageUrl': '', 'category': 'عام', 'readTime': 3, 'date': DateTime.now(), 'slug': '', 'views': 0,
                });
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(doc != null ? 'حفظ' : 'إضافة'),
          ),
        ],
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
    final titleCtrl = TextEditingController(text: doc?.data()['title'] ?? '');
    final catCtrl = TextEditingController(text: doc?.data()['category'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(doc != null ? 'تعديل شرح' : 'إضافة شرح'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'التصنيف', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (doc != null) {
                await doc.reference.update({'title': titleCtrl.text, 'category': catCtrl.text});
              } else {
                await FirebaseFirestore.instance.collection('tutorials').add({
                  'title': titleCtrl.text, 'category': catCtrl.text, 'thumbnailUrl': '', 'readTime': 5, 'url': '', 'views': 0,
                });
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(doc != null ? 'حفظ' : 'إضافة'),
          ),
        ],
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
    final titleCtrl = TextEditingController(text: doc?.data()['title'] ?? '');
    final sourceCtrl = TextEditingController(text: doc?.data()['source'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(doc != null ? 'تعديل خبر' : 'إضافة خبر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: sourceCtrl, decoration: const InputDecoration(labelText: 'المصدر', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (doc != null) {
                await doc.reference.update({'title': titleCtrl.text, 'source': sourceCtrl.text});
              } else {
                await FirebaseFirestore.instance.collection('news').add({
                  'title': titleCtrl.text, 'source': sourceCtrl.text, 'date': DateTime.now(), 'url': '', 'views': 0,
                });
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(doc != null ? 'حفظ' : 'إضافة'),
          ),
        ],
      ),
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
