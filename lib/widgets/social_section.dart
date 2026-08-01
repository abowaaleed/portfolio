import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class SocialSection extends StatelessWidget {
  const SocialSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'تواصل معي', subtitle: 'على منصات التواصل'),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('social_links').orderBy('order').snapshots(),
            builder: (ctx, snap) {
              final items = snap.data?.docs ?? [];
              if (!snap.hasData) {
                return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
              }
              if (items.isEmpty) {
                return Center(child: Text('لا توجد روابط بعد', style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)));
              }
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: items.map((doc) => _SocialCard(data: doc.data() as Map<String, dynamic>, isDark: isDark)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SocialCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;
  const _SocialCard({required this.data, required this.isDark});

  IconData _icon(String name) {
    switch (name) {
      case 'x-twitter': return Icons.alternate_email;
      case 'github': return Icons.code;
      case 'telegram': return Icons.send;
      case 'instagram': return Icons.camera_alt_outlined;
      case 'snapchat': return Icons.star;
      case 'youtube': return Icons.play_circle_filled;
      case 'linkedin': return Icons.work;
      case 'tiktok': return Icons.music_note;
      case 'whatsapp': return Icons.chat;
      case 'website': return Icons.language;
      default: return Icons.link;
    }
  }

  Color _color(String name) {
    switch (name) {
      case 'x-twitter': return const Color(0xFF000000);
      case 'github': return const Color(0xFF333333);
      case 'telegram': return const Color(0xFF0088CC);
      case 'instagram': return const Color(0xFFE4405F);
      case 'snapchat': return const Color(0xFFFFFC00);
      case 'youtube': return const Color(0xFFFF0000);
      case 'linkedin': return const Color(0xFF0A66C2);
      case 'tiktok': return const Color(0xFF000000);
      case 'whatsapp': return const Color(0xFF25D366);
      case 'website': return AppColors.accent;
      default: return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = data['iconName'] as String? ?? '';
    final url = data['url'] as String? ?? '';
    final label = data['name'] as String? ?? '';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: url.isNotEmpty ? () async {
        if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url));
      } : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon(name), size: 18, color: _color(name)),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
        const SizedBox(height: 10),
        Container(width: 50, height: 3, decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentPink]),
        )),
      ],
    );
  }
}
