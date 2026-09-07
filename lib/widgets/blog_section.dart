import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'site_text.dart';

class BlogSection extends StatelessWidget {
  const BlogSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('blog').snapshots(),
      builder: (ctx, snap) {
        final posts = [...?snap.data?.docs];
        posts.sort((a, b) {
          final da = (a.data() as Map<String, dynamic>)['date'];
          final db = (b.data() as Map<String, dynamic>)['date'];
          final ad = da is Timestamp ? da.toDate() : da is DateTime ? da : DateTime.fromMillisecondsSinceEpoch(0);
          final bd = db is Timestamp ? db.toDate() : db is DateTime ? db : DateTime.fromMillisecondsSinceEpoch(0);
          return bd.compareTo(ad);
        });
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(titleField: 'blogTitle', title: 'المدونة', subtitleField: 'blogSubtitle', subtitle: 'تدوينات البرمجة والتقنية'),
              const SizedBox(height: 16),
              if (snap.hasError)
                const SizedBox(height: 60, child: Center(child: Text('خطأ في تحميل المدونة', style: TextStyle(color: Colors.redAccent, fontSize: 13)))),
              if (!snap.hasData)
                const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              else if (posts.isEmpty)
                _EmptyPlaceholder(icon: Icons.article, text: 'لا توجد تدوينات بعد')
              else
                Wrap(spacing: 12, runSpacing: 12,
                  children: posts.map((doc) => _BlogCard(data: doc.data() as Map<String, dynamic>, isDark: isDark)).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BlogCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;
  const _BlogCard({required this.data, required this.isDark});

  Widget _BlogImage({required Map<String, dynamic> data}) {
    final img = data['imageBase64'] as String?;
    if (img != null && img.isNotEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          image: DecorationImage(image: MemoryImage(base64Decode(img.split(',').last)), fit: BoxFit.cover),
        ),
      );
    }
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Center(child: Icon(Icons.article, color: AppColors.accent.withValues(alpha: 0.3), size: 36)),
    );
  }

  void _showFull(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContentSheet(data: data, isDark: isDark, title: 'مدونة', icon: Icons.article),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width > 768 ? 320.0 : double.infinity;
    final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: () => _showFull(context),
        child: Card(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BlogImage(data: data),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.accentPurple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                          child: Text(data['category'] as String? ?? '', style: const TextStyle(fontSize: 10, color: AppColors.accentPurple, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.schedule, size: 10, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                        const SizedBox(width: 2),
                        Text('${data['readTime'] ?? 3} د', style: TextStyle(fontSize: 10, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(data['title'] as String? ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
                    const SizedBox(height: 4),
                    Text(data['excerpt'] as String? ?? '', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, height: 1.3), maxLines: 3),
                    const SizedBox(height: 8),
                    Text('${date.day}/${date.month}/${date.year}', style: TextStyle(fontSize: 10, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String titleField;
  final String title;
  final String subtitleField;
  final String subtitle;
  const _SectionHeader({required this.titleField, required this.title, required this.subtitleField, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SiteText(titleField, fallback: title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
        const SizedBox(height: 2),
        SiteText(subtitleField, fallback: subtitle, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
        const SizedBox(height: 10),
        Container(width: 50, height: 3, decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: const LinearGradient(colors: [AppColors.success, AppColors.accent]),
        )),
      ],
    );
  }
}

class _ContentSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;
  final String title;
  final IconData icon;
  const _ContentSheet({required this.data, required this.isDark, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final img = data['imageBase64'] as String?;
    final content = data['content'] as String? ?? data['description'] as String? ?? '';
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F0F1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
            )),
            if (img != null && img.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(base64Decode(img.split(',').last), width: double.infinity, height: 180, fit: BoxFit.cover),
              ),
            if (img != null && img.isNotEmpty) const SizedBox(height: 16),
            Row(children: [
              Icon(icon, size: 18, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 12, color: AppColors.accent)),
            ]),
            const SizedBox(height: 8),
            Text(data['title'] as String? ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
            if (data['source'] != null) ...[
              const SizedBox(height: 4),
              Text(data['source'] as String? ?? '', style: TextStyle(fontSize: 12, color: AppColors.accent)),
            ],
            if (content.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(content, style: TextStyle(fontSize: 14, height: 1.6, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyPlaceholder({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Icon(icon, size: 32, color: (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.4)),
          const SizedBox(height: 6),
          Text(text, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
        ],
      ),
    );
  }
}
