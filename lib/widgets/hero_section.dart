import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'site_text.dart';

class HeroSection extends StatelessWidget {
  final ScrollController scrollController;

  const HeroSection({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('settings').doc('profile').snapshots(),
      builder: (ctx, snap) {
        if (snap.hasError) {
          return const SizedBox(height: 300, child: Center(child: Text('خطأ في تحميل البيانات', style: TextStyle(color: Colors.redAccent))));
        }
        final data = snap.data?.data() as Map<String, dynamic>?;
        final profImg = data?['profileImageBase64'] as String?;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          height: size.height * 0.55,
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _GridPainter(isDark: isDark))),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accent, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.darkCard,
                        backgroundImage: profImg != null ? MemoryImage(base64Decode(profImg.split(',').last)) : null,
                        child: profImg == null ? Text('S', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.accent, fontFamily: 'monospace')) : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SiteText('heroName', fallback: 'صالح الحودي', style: TextStyle(fontSize: size.width > 600 ? 40 : 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.lightTextPrimary, height: 1.2)),
                    const SizedBox(height: 4),
                    SiteText('heroSubtitle', fallback: 'Saleh Alhoodi — موقع صالح الحودي', style: TextStyle(fontSize: size.width > 600 ? 18 : 13, color: AppColors.accent, fontFamily: 'monospace', letterSpacing: 1)),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: SiteText(
                        'heroDescription',
                        fallback: 'مطوّر تطبيقات وأنظمة • شغوف بالتقنية والتراث السعودي',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: size.width > 600 ? 14 : 12, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _HeroButton(label: 'تطبيقاتي', field: 'heroAppsButton', icon: Icons.apps, onTap: () => scrollController.animateTo(500, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut), isPrimary: true),
                        const SizedBox(width: 12),
                        _HeroButton(label: 'تواصل', field: 'heroContactButton', icon: Icons.chat_bubble_outline, onTap: () => scrollController.animateTo(2100, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut), isPrimary: false),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroButton extends StatelessWidget {
  final String label;
  final String field;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _HeroButton({required this.label, required this.field, required this.icon, required this.onTap, required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: SiteText(field, fallback: label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        backgroundColor: isPrimary ? AppColors.accent : (isDark ? AppColors.darkCard : const Color(0xFFE2E8F0)),
        foregroundColor: isPrimary ? Colors.black : (isDark ? Colors.white : AppColors.lightTextPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
