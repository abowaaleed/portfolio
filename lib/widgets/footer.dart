import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.code, color: AppColors.accent, size: 20),
              const SizedBox(width: 6),
              Text('صالح الحودي', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          Text('© 2026 Saleh Alhoodi. All rights reserved.', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
          const SizedBox(height: 4),
          Text('مبني بـ Flutter Web', style: TextStyle(fontSize: 12, color: AppColors.accent, fontFamily: 'monospace')),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FooterLink(label: 'الرئيسية'),
              _FooterLink(label: 'تطبيقاتي'),
              _FooterLink(label: 'الشروحات'),
              _FooterLink(label: 'المدونة'),
              _FooterLink(label: 'تواصل معي'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;

  const _FooterLink({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextButton(
        onPressed: () {},
        child: Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
      ),
    );
  }
}
