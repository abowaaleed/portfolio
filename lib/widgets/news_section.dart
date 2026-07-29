import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';

class NewsSection extends StatelessWidget {
  const NewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'أخبار التقنية', subtitle: 'آخر المستجدات في عالم التقنية'),
          const SizedBox(height: 16),
          ...mockNews.map((n) => _NewsCard(news: n, isDark: isDark)),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
        const SizedBox(height: 16),
        Container(width: 60, height: 3, decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: const LinearGradient(colors: [AppColors.accentPink, AppColors.warning]),
        )),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  final dynamic news;
  final bool isDark;

  const _NewsCard({required this.news, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(Icons.newspaper, color: AppColors.accent, size: 28),
        title: Text(news.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
        subtitle: Row(
          children: [
            Text(news.source, style: TextStyle(fontSize: 11, color: AppColors.accent)),
            const SizedBox(width: 8),
            Text('•', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
            const SizedBox(width: 8),
            Text('${DateTime.now().difference(news.date).inDays} يوم', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
          ],
        ),
        trailing: Icon(Icons.chevron_left, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, size: 20),
      ),
    );
  }
}
