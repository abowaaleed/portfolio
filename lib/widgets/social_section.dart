import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';

IconData _iconFor(String name) {
  switch (name) {
    case 'x-twitter': return Icons.alternate_email;
    case 'github': return Icons.code;
    case 'telegram': return Icons.send;
    case 'instagram': return Icons.camera_alt_outlined;
    case 'snapchat': return Icons.star;
    case 'youtube': return Icons.play_circle_filled;
    case 'linkedin': return Icons.business_center;
    default: return Icons.link;
  }
}

class SocialSection extends StatelessWidget {
  const SocialSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'تواصل معي', subtitle: 'تابعني على منصات التواصل الاجتماعي'),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: mockSocialLinks.map((s) => _SocialIcon(link: s, isDark: isDark)).toList(),
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
          gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentPink]),
        )),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final dynamic link;
  final bool isDark;

  const _SocialIcon({required this.link, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Tooltip(
        message: link.name,
        child: IconButton(
          onPressed: () async {
            if (link.url.isNotEmpty && await canLaunchUrl(Uri.parse(link.url))) {
              await launchUrl(Uri.parse(link.url));
            }
          },
          icon: Icon(_iconFor(link.iconName), size: 24),
          style: IconButton.styleFrom(
            foregroundColor: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
            backgroundColor: (isDark ? AppColors.darkCard : AppColors.lightCard),
            padding: const EdgeInsets.all(14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE2E8F0)),
          ),
        ),
      ),
    );
  }
}
