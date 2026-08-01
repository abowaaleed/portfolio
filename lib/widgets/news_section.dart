import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'news_detail_sheet.dart';

class NewsSection extends StatefulWidget {
  const NewsSection({super.key});

  @override
  State<NewsSection> createState() => _NewsSectionState();
}

class _NewsTab {
  final String collection;
  final String label;
  final IconData icon;
  final bool isTrend;
  const _NewsTab({
    required this.collection,
    required this.label,
    required this.icon,
    this.isTrend = false,
  });
}

class _NewsSectionState extends State<NewsSection> with SingleTickerProviderStateMixin {
  static const tabs = <_NewsTab>[
    _NewsTab(collection: 'tech_news', label: 'أخبار التقنية', icon: Icons.phone_android),
    _NewsTab(collection: 'google_trends', label: 'ترند جوجل', icon: Icons.trending_up, isTrend: true),
    _NewsTab(collection: 'twitter_trends', label: 'ترند X', icon: Icons.alternate_email, isTrend: true),
    _NewsTab(collection: 'saudi_news', label: 'أخبار سعودية', icon: Icons.flag),
    _NewsTab(collection: 'global_news', label: 'نبض عالمي', icon: Icons.public),
  ];

  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'الأخبار والترندات', subtitle: 'أبرز التقنية والترندات السعودية والعالمية'),
          const SizedBox(height: 12),
          TabBar(
            controller: _controller,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.accent,
            unselectedLabelColor: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
            indicatorColor: AppColors.accent,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE2E8F0),
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: tabs
                .map((t) => Tab(
                      height: 38,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(t.icon, size: 16),
                          const SizedBox(width: 6),
                          Text(t.label),
                        ],
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 235,
            child: TabBarView(
              controller: _controller,
              children: tabs.map((t) => _NewsStream(tab: t, isDark: isDark)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsStream extends StatelessWidget {
  final _NewsTab tab;
  final bool isDark;
  const _NewsStream({required this.tab, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(tab.collection)
          .orderBy('date', descending: true)
          .limit(12)
          .snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (docs.isEmpty) {
          return _EmptyPlaceholder(
            icon: tab.isTrend ? Icons.trending_up : Icons.newspaper,
            text: 'لا توجد عناصر في هذا القسم بعد',
          );
        }
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _NewsCard(data: data, isDark: isDark, isTrend: tab.isTrend, rank: i + 1);
          },
        );
      },
    );
  }
}

class _NewsCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;
  final bool isTrend;
  final int rank;
  const _NewsCard({required this.data, required this.isDark, required this.isTrend, required this.rank});

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
    final category = (data['category'] as String? ?? '').trim();
    final source = (data['source'] as String? ?? '').trim();
    final traffic = (data['approxTraffic'] as String? ?? '').trim();
    final summary = (data['summary'] as String? ?? data['content'] as String? ?? data['description'] as String? ?? '').trim();

    return GestureDetector(
      onTap: () => _showFull(context),
      child: Container(
        width: 280,
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
              height: 78,
              child: NewsThumb(
                base64: imgBase64,
                url: imgUrl,
                height: 78,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isTrend) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('#$rank', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF03222B))),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (category.isNotEmpty)
                          Expanded(
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
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3, color: isDark ? Colors.white : AppColors.lightTextPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (summary.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          summary,
                          style: TextStyle(fontSize: 11, height: 1.4, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (source.isNotEmpty || traffic.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 12, color: AppColors.accentPurple),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              source.isNotEmpty ? source : 'ترند',
                              style: TextStyle(fontSize: 10, color: AppColors.accent),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (traffic.isNotEmpty)
                            Text(traffic, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.accentPurple)),
                        ],
                      ),
                    ],
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
