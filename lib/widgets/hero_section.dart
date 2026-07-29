import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HeroSection extends StatelessWidget {
  final ScrollController scrollController;

  const HeroSection({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      height: size.height * 0.7,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter(isDark: isDark)),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accent, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.darkCard,
                    child: Text('S', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.accent, fontFamily: 'monospace')),
                  ),
                ),
                const SizedBox(height: 24),
                Text('صالح الحودي', style: TextStyle(fontSize: size.width > 600 ? 48 : 36, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.lightTextPrimary, height: 1.2)),
                const SizedBox(height: 8),
                Text('Saleh Alhoodi', style: TextStyle(fontSize: size.width > 600 ? 24 : 18, color: AppColors.accent, fontFamily: 'monospace', letterSpacing: 2)),
                const SizedBox(height: 16),
                Text(
                  'مطوّر تطبيقات وأنظمة • شغوف بالتقنية والتراث السعودي وتطبيقات الحياة اليومية',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: size.width > 600 ? 16 : 14, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, height: 1.6),
                ),
                const SizedBox(height: 12),
                Text(
                  'أُحوِّل الأفكار إلى تطبيقات تُسهِّل الحياة',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: size.width > 600 ? 14 : 12, color: AppColors.accentPurple, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _HeroButton(
                      label: 'استعرض تطبيقاتي',
                      icon: Icons.apps,
                      onTap: () => scrollController.animateTo(600, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut),
                      isPrimary: true,
                    ),
                    const SizedBox(width: 16),
                    _HeroButton(
                      label: 'تواصل معي',
                      icon: Icons.chat_bubble_outline,
                      onTap: () => scrollController.animateTo(3100, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut),
                      isPrimary: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _HeroButton({required this.label, required this.icon, required this.onTap, required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        backgroundColor: isPrimary ? AppColors.accent : (isDark ? AppColors.darkCard : const Color(0xFFE2E8F0)),
        foregroundColor: isPrimary ? Colors.black : (isDark ? Colors.white : AppColors.lightTextPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: isPrimary ? BorderSide.none : BorderSide(color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFCBD5E1)),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final bool isDark;

  _GridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03)
      ..strokeWidth = 1;
    const step = 60.0;
    for (double x = 0; x < size.width; x += step) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += step) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
