import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';

class AppsSection extends StatelessWidget {
  const AppsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final apps = mockApps;
    final pinned = apps.where((a) => a.isPinned).toList();
    final others = apps.where((a) => !a.isPinned).toList();
    final ordered = [...pinned, ...others];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'تطبيقاتي', subtitle: 'تطبيقات وأدوات طورتها لتسهيل حياتك اليومية'),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: ordered.map((app) => _AppCard(app: app, isDark: isDark)).toList(),
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
          gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentPurple]),
        )),
      ],
    );
  }
}

class _AppCard extends StatelessWidget {
  final dynamic app;
  final bool isDark;

  const _AppCard({required this.app, required this.isDark});

  Color _statusColor() {
    switch (app.status.name) {
      case 'published': return AppColors.success;
      case 'beta': return AppColors.warning;
      default: return AppColors.textSecondary;
    }
  }

  String _statusLabel() {
    switch (app.status.name) {
      case 'published': return 'منشور';
      case 'beta': return 'تجريبي';
      default: return 'قيد التطوير';
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width > 768 ? 320.0 : double.infinity;
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.picture_as_pdf, color: AppColors.accent, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(app.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(app.description, style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, height: 1.5)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor().withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(_statusLabel(), style: TextStyle(fontSize: 11, color: _statusColor(), fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  if (app.url.isNotEmpty)
                    TextButton.icon(
                      onPressed: () async {
                        if (await canLaunchUrl(Uri.parse(app.url))) {
                          await launchUrl(Uri.parse(app.url));
                        }
                      },
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: const Text('تجربة', style: TextStyle(fontSize: 13)),
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
