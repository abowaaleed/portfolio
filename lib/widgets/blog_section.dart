import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';

class BlogSection extends StatelessWidget {
  const BlogSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'المدونة', subtitle: 'تدويناتي في البرمجة والتقنية'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: mockBlogPosts.map((p) => _BlogCard(post: p, isDark: isDark)).toList(),
          ),
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
          gradient: const LinearGradient(colors: [AppColors.success, AppColors.accent]),
        )),
      ],
    );
  }
}

class _BlogCard extends StatelessWidget {
  final dynamic post;
  final bool isDark;

  const _BlogCard({required this.post, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width > 768 ? 380.0 : double.infinity;
    return SizedBox(
      width: width,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(child: Icon(Icons.article, color: AppColors.accent.withValues(alpha: 0.3), size: 48)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(post.category, style: const TextStyle(fontSize: 11, color: AppColors.accentPurple, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.schedule, size: 11, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                      const SizedBox(width: 3),
                      Text('${post.readTime} دقائق', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(post.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
                  const SizedBox(height: 6),
                  Text(post.excerpt, style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, height: 1.4)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('${post.date.day}/${post.date.month}/${post.date.year}', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
                      const Spacer(),
                      Text('اقرأ المزيد →', style: TextStyle(fontSize: 13, color: AppColors.accent, fontFamily: 'monospace')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
