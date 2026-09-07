import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import 'site_text.dart';

class AppsSection extends StatelessWidget {
  const AppsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('apps').snapshots(),
      builder: (ctx, snap) {
        final apps = [...?snap.data?.docs];
        apps.sort((a, b) {
          final pa = (a.data() as Map<String, dynamic>)['isPinned'] as bool? ?? false;
          final pb = (b.data() as Map<String, dynamic>)['isPinned'] as bool? ?? false;
          return (pb ? 1 : 0).compareTo(pa ? 1 : 0);
        });
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(titleField: 'appsTitle', title: 'تطبيقاتي', subtitleField: 'appsSubtitle', subtitle: 'تطبيقات وأدوات طورتها'),
              const SizedBox(height: 16),
              if (snap.hasError)
                const SizedBox(height: 60, child: Center(child: Text('خطأ في تحميل التطبيقات', style: TextStyle(color: Colors.redAccent, fontSize: 13)))),
              if (!snap.hasData)
                const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              else if (apps.isEmpty)
                _EmptyPlaceholder(icon: Icons.apps, text: 'لا توجد تطبيقات بعد')
              else
                Wrap(spacing: 12, runSpacing: 12,
                  children: apps.map((doc) => _AppCard(data: doc.data() as Map<String, dynamic>, docId: doc.id, isDark: isDark)).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AppCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool isDark;
  const _AppCard({required this.data, required this.docId, required this.isDark});

  Widget _AppIcon({required Map<String, dynamic> data}) {
    final img = data['imageBase64'] as String?;
    if (img != null && img.isNotEmpty) {
      return Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(image: MemoryImage(base64Decode(img.split(',').last)), fit: BoxFit.cover),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(Icons.picture_as_pdf, color: AppColors.accent, size: 22),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width > 768 ? 280.0 : double.infinity;
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  Row(
                children: [
                  _AppIcon(data: data),
                  const SizedBox(width: 10),
                  Expanded(child: Text(data['name'] as String? ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary))),
                ],
              ),
              const SizedBox(height: 8),
              Text(data['description'] as String? ?? '', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, height: 1.4), maxLines: 2),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StatusBadge(status: data['status'] as String? ?? 'published'),
                  const Spacer(),
                  if ((data['url'] as String? ?? '').isNotEmpty)
                    GestureDetector(
                      onTap: () async {
                        final url = data['url'] as String? ?? '';
                        if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url));
                          FirestoreService.incrementAppClick(docId).catchError((_) {});
                        }
                      },
                      child: Text('فتح →', style: TextStyle(fontSize: 12, color: AppColors.accent, fontFamily: 'monospace')),
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

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color _color() {
    switch (status) {
      case 'published': return AppColors.success;
      case 'beta': return AppColors.warning;
      default: return AppColors.textSecondary;
    }
  }

  String _label() {
    switch (status) {
      case 'published': return 'منشور';
      case 'beta': return 'تجريبي';
      default: return 'تطوير';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: _color().withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(_label(), style: TextStyle(fontSize: 10, color: _color(), fontWeight: FontWeight.w600)),
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
          gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentPurple]),
        )),
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
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 40, color: (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
        ],
      ),
    );
  }
}
