import 'package:flutter/material.dart';
import '../data/mock_data.dart';
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
    final categories = ['الكل', ...mockTutorials.map((t) => t.category).toSet()];
    final filtered = _selectedCategory == 'الكل' ? mockTutorials : mockTutorials.where((t) => t.category == _selectedCategory).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'الشروحات', subtitle: 'شروحات ودروس تقنية في مجالات متعددة'),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: cat == _selectedCategory,
                  onSelected: (v) => setState(() => _selectedCategory = cat),
                  selectedColor: AppColors.accent.withValues(alpha: 0.2),
                  labelStyle: TextStyle(fontSize: 13, color: cat == _selectedCategory ? AppColors.accent : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: filtered.map((t) => _TutorialCard(tutorial: t, isDark: isDark)).toList(),
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
          gradient: const LinearGradient(colors: [AppColors.accentPurple, AppColors.accentPink]),
        )),
      ],
    );
  }
}

class _TutorialCard extends StatelessWidget {
  final dynamic tutorial;
  final bool isDark;

  const _TutorialCard({required this.tutorial, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width > 768 ? 280.0 : double.infinity;
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(Icons.play_circle_outline, color: AppColors.accentPurple, size: 40),
                ),
              ),
              const SizedBox(height: 12),
              Text(tutorial.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 12, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                  const SizedBox(width: 4),
                  Text('${tutorial.readTime} دقائق', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(tutorial.category, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
