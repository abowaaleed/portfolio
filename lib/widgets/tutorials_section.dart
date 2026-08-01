import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class TutorialsSection extends StatefulWidget {
  const TutorialsSection({super.key});

  @override
  State<TutorialsSection> createState() => _TutorialsSectionState();
}

class _TutorialsSectionState extends State<TutorialsSection> {
  String _selectedCategory = 'الكل';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tutorials').snapshots(),
      builder: (ctx, snap) {
        final tutorials = snap.data?.docs ?? [];
        final categories = ['الكل', ...tutorials.map((d) => (d.data() as Map<String, dynamic>)['category'] as String? ?? 'عام').toSet()];
        final filtered = _selectedCategory == 'الكل' ? tutorials : tutorials.where((d) => ((d.data() as Map<String, dynamic>)['category'] as String? ?? '') == _selectedCategory).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'الشروحات', subtitle: 'دروس تقنية'),
              const SizedBox(height: 12),
              if (!snap.hasData)
                const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              else ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ChoiceChip(
                        label: Text(cat, style: const TextStyle(fontSize: 12)),
                        selected: cat == _selectedCategory,
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                        selectedColor: AppColors.accent.withValues(alpha: 0.2),
                        labelStyle: TextStyle(fontSize: 12, color: cat == _selectedCategory ? AppColors.accent : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
                        visualDensity: VisualDensity.compact,
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  _EmptyPlaceholder(icon: Icons.school, text: 'لا توجد شروحات بعد')
                else
                  Wrap(spacing: 12, runSpacing: 12,
                    children: filtered.map((doc) => _TutorialCard(data: doc.data() as Map<String, dynamic>, isDark: isDark)).toList(),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TutorialCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;
  const _TutorialCard({required this.data, required this.isDark});

  Widget _TutorialImage({required Map<String, dynamic> data}) {
    final img = data['imageBase64'] as String?;
    if (img != null && img.isNotEmpty) {
      return Container(
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(image: MemoryImage(base64Decode(img.split(',').last)), fit: BoxFit.cover),
        ),
      );
    }
    return Container(
      height: 80,
      decoration: BoxDecoration(color: AppColors.accentPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Center(child: Icon(Icons.play_circle_outline, color: AppColors.accentPurple, size: 32)),
    );
  }

  void _showFull(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContentSheet(data: data, isDark: isDark, title: 'شرح', icon: Icons.play_circle_outline),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width > 768 ? 240.0 : double.infinity;
    final content = data['content'] as String? ?? data['description'] as String? ?? '';
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: () => _showFull(context),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TutorialImage(data: data),
                const SizedBox(height: 10),
                Text(data['title'] as String? ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
                if (content.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(content, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 11, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                    const SizedBox(width: 3),
                    Text('${data['readTime'] ?? 5} د', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(data['category'] as String? ?? '', style: TextStyle(fontSize: 10, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
        const SizedBox(height: 10),
        Container(width: 50, height: 3, decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: const LinearGradient(colors: [AppColors.accentPurple, AppColors.accentPink]),
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
