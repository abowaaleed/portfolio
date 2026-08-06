import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'site_text.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.code, color: AppColors.accent, size: 18),
              const SizedBox(width: 6),
              SiteText('footerName', fallback: 'صالح الحودي', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          SiteText('footerCopyright', fallback: '© 2026 Saleh Alhoodi. جميع الحقوق محفوظة.', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
          const SizedBox(height: 4),
          Text('${AppInfo.version} — Flutter Web', style: TextStyle(fontSize: 11, color: AppColors.accent, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
