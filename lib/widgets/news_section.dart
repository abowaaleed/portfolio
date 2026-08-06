import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import 'news_detail_sheet.dart';
import 'site_text.dart';

class NewsSection extends StatelessWidget {
  const NewsSection({super.key});

  static const _sections = <_NewsSectionDef>[
    _NewsSectionDef(
      collection: 'tech_news',
      title: 'أخبار التقنية',
      subtitle: 'أحدث مستجدات عالم التقنية',
      icon: Icons.phone_android,
      color: Color(0xFF00D4FF),
    ),
    _NewsSectionDef(
      collection: 'saudi_news',
      title: 'الأخبار المحلية',
      subtitle: 'آخر أخبار وتنمية السعودية',
      icon: Icons.flag,
      color: Color(0xFF34A853),
    ),
    _NewsSectionDef(
      collection: 'google_trends',
      title: 'ترند Google',
      subtitle: 'أكثر ما يبحث عنه السعوديون الآن',
      icon: Icons.trending_up,
      color: Color(0xFF4285F4),
      isTrend: true,
    ),
    _NewsSectionDef(
      collection: 'twitter_trends',
      title: 'ترند X',
      subtitle: 'الأكثر تداولاً على منصة X الآن',
      icon: Icons.alternate_email,
      color: Color(0xFF1DA1F2),
      isTrend: true,
    ),
    _NewsSectionDef(
      collection: 'global_news',
      title: 'نبض عالمي',
      subtitle: 'أبرز أحداث العالم الكبرى',
      icon: Icons.public,
      color: Color(0xFFFBBC05),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(titleField: 'newsTitle', title: 'الأخبار والترندات', subtitleField: 'newsSubtitle', subtitle: 'تقنية • محلية • ترندات • عالمي'),
          const SizedBox(height: 20),
          ..._sections.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: _NewsStream(section: s, isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsSectionDef {
  final String collection;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isTrend;
  const _NewsSectionDef({
    required this.collection,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isTrend = false,
  });
}

class _NewsStream extends StatelessWidget {
  final _NewsSectionDef section;
  final bool isDark;
  const _NewsStream({required this.section, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: section.color.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(section.icon, size: 18, color: section.color),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary),
                ),
                const SizedBox(height: 1),
                Text(section.subtitle, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
              ],
            ),
            const Spacer(),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection(section.collection).snapshots(),
              builder: (ctx, snap) {
                final n = snap.data?.docs.length ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: section.color.withValues(alpha: isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$n عنصراً', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: section.color)),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(section.collection)
              .orderBy('date', descending: true)
              .limit(10)
              .snapshots(),
          builder: (ctx, snap) {
            final docs = snap.data?.docs ?? [];
            if (!snap.hasData) {
              return const SizedBox(height: 170, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
            }
            if (docs.isEmpty) {
              return _EmptyPlaceholder(icon: section.icon, text: 'لا توجد عناصر في هذا القسم بعد');
            }
            return SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return _NewsCard(data: data, isDark: isDark, isTrend: section.isTrend, rank: i + 1);
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;
  final bool isTrend;
  final int rank;
  const _NewsCard({required this.data, required this.isDark, required this.isTrend, required this.rank});

  String get _sourceUrl => (data['url'] as String? ?? data['link'] as String? ?? '').trim();
  String get _summary => (data['summary'] as String? ?? data['content'] as String? ?? data['description'] as String? ?? '').trim();

  Future<void> _openSource(BuildContext context) async {
    final uri = Uri.tryParse(_sourceUrl);
    if (uri == null || !uri.hasScheme) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('لا يوجد رابط للمصدر')));
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
    }
  }

  Future<void> _openDetail(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewsDetailSheet(data: data, isDark: isDark),
    );
  }

  Future<void> _copySummary(BuildContext context) async {
    final text = _summary.isNotEmpty ? _summary : (data['title'] as String? ?? '');
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: const Text('تم نسخ الملخص إلى الحافظة'),
          behavior: SnackBarBehavior.floating,
          width: 300,
        ));
    }
  }

  String _formatDate() {
    final value = data['createdAt'] ?? data['date'] ?? data['publishedAt'];
    if (value == null) return '';
    DateTime dt;
    if (value is DateTime) {
      dt = value;
    } else if (value is Timestamp) {
      dt = value.toDate();
    } else {
      final s = value.toString();
      dt = DateTime.tryParse(s) ?? DateTime.now();
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    String two(int n) => n.toString().padLeft(2, '0');
    final hm = '${two(dt.hour)}:${two(dt.minute)}';
    if (day == today) return 'اليوم $hm';
    if (day == today.subtract(const Duration(days: 1))) return 'أمس $hm';
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} $hm';
  }

  @override
  Widget build(BuildContext context) {
    final imgBase64 = data['imageBase64'] as String?;
    final imgUrl = data['imageUrl'] as String?;
    final category = (data['category'] as String? ?? '').trim();
    final source = (data['source'] as String? ?? '').trim();
    final traffic = (data['approxTraffic'] as String? ?? '').trim();
    final dateLabel = _formatDate();

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        width: 290,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 80,
              child: NewsThumb(
                base64: imgBase64,
                url: imgUrl,
                height: 80,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 12, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                        const SizedBox(width: 4),
                        Text(
                          dateLabel.isEmpty ? 'غير محدد' : dateLabel,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                        ),
                        const Spacer(),
                        if (isTrend) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(6)),
                            child: Text('#$rank', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF03222B))),
                          ),
                        ] else if (category.isNotEmpty)
                          Flexible(
                            child: Text(
                              category,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.accent),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['title'] as String? ?? '',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.3, color: isDark ? Colors.white : AppColors.lightTextPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_summary.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          _summary,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(fontSize: 11, height: 1.4, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _sourceUrl.isNotEmpty ? () => _openSource(context) : null,
                            child: Row(
                              children: [
                                Icon(Icons.auto_awesome, size: 12, color: AppColors.accentPurple),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    source.isNotEmpty ? source : 'قراءة المزيد',
                                    style: const TextStyle(fontSize: 10, color: AppColors.accent, decoration: TextDecoration.underline),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (traffic.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Text(traffic, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.accentPurple)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => _copySummary(context),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: isDark ? 0.15 : 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy_rounded, size: 12, color: AppColors.accent),
                                const SizedBox(width: 4),
                                Text('نسخ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.accent)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
  final String titleField;
  final String title;
  final String subtitleField;
  final String subtitle;
  const _SectionHeader({required this.titleField, required this.title, required this.subtitleField, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SiteText(titleField, fallback: title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
            const SizedBox(height: 2),
            SiteText(subtitleField, fallback: subtitle, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
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
