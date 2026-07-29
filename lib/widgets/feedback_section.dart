import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FeedbackSection extends StatefulWidget {
  const FeedbackSection({super.key});

  @override
  State<FeedbackSection> createState() => _FeedbackSectionState();
}

class _FeedbackSectionState extends State<FeedbackSection> {
  final _nameCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  double _rating = 5;
  String? _reaction;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'رأيك يهمني', subtitle: 'شاركني باقتراح أو تعليق'),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ما رأيك في الصفحة؟', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'اسمك (اختياري)',
                      filled: true,
                      fillColor: isDark ? AppColors.darkBg : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'اكتب رأيك أو اقتراحك...',
                      filled: true,
                      fillColor: isDark ? AppColors.darkBg : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ...['👍', '😍', '🤔', '🔥'].map((e) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(e, style: const TextStyle(fontSize: 20)),
                          selected: _reaction == e,
                          onSelected: (v) => setState(() => _reaction = v ? e : null),
                          selectedColor: AppColors.accent.withValues(alpha: 0.2),
                        ),
                      )),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('شكرًا لمشاركتك! سيتم مراجعة تعليقك قبل النشر.')),
                          );
                          _nameCtrl.clear();
                          _commentCtrl.clear();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('إرسال'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('سيتم مراجعة تعليقك قبل النشر', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
                ],
              ),
            ),
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
          gradient: const LinearGradient(colors: [AppColors.accentPink, AppColors.accentPurple]),
        )),
      ],
    );
  }
}
