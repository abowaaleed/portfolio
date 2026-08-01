import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'news_detail_sheet.dart';

class NewsSection extends StatelessWidget {
  const NewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('news').orderBy('date', descending: true).limit(10).snapshots(),
      builder: (ctx, snap) {
        final news = snap.data?.docs ?? [];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'أخبار التقنية', subtitle: 'آخر المستجدات'),
              const SizedBox(height: 16),
              if (!snap.hasData)
                const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              else if (news.isEmpty)
                _EmptyPlaceholder(icon: Icons.newspaper, text: 'لا توجد أخبار بعد')
              else
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: news.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final data = news[i].data() as Map<String, dynamic>;
                      return _NewsCard(data: data, isDark: isDark);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NewsCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;
  const _NewsCard({required this.data, required this.isDark});

  void _showFull(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewsDetailSheet(data: data, isDark: isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imgBase64 = data['imageBase64'] as String?;
    final imgUrl = data['imageUrl'] as String?;
    final content = data['content'] as String? ?? data['description'] as String? ?? '';
    final hasImage = (imgBase64 != null && imgBase64.isNotEmpty) || (imgUrl != null && imgUrl.isNotEmpty);
    return GestureDetector(
      onTap: () => _showFull(context),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              NewsThumb(
                base64: imgBase64,
                url: imgUrl,
                height: 70,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.newspaper, size: 14, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(data['title'] as String? ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
                        ),
                      ],
                    ),
                    if (content.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(content, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary), maxLines: 3, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(data['source'] as String? ?? '', style: TextStyle(fontSize: 10, color: AppColors.accent)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
          ],
        ),
        const Spacer(),
        Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.accent),
      ],
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
