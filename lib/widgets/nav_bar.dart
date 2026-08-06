import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'site_text.dart';

class NavBar extends StatefulWidget {
  final void Function(int index)? onSectionTap;
  final ScrollController scrollController;

  const NavBar({super.key, this.onSectionTap, required this.scrollController});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  bool _isScrolled = false;
  bool _isMobileOpen = false;

  static const sections = ['الرئيسية', 'تطبيقاتي', 'الشروحات', 'أخبار', 'المدونة', 'تواصل'];
  static const sectionFields = ['navHome', 'navApps', 'navTutorials', 'navNews', 'navBlog', 'navContact'];

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final scrolled = widget.scrollController.offset > 50;
    if (scrolled != _isScrolled) setState(() => _isScrolled = scrolled);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _scrollTo(int index) {
    final offsets = [0.0, 500.0, 900.0, 1300.0, 1700.0, 2100.0];
    final target = index < offsets.length ? offsets[index] : 2100.0;
    widget.scrollController.animateTo(target, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    setState(() => _isMobileOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark
        ? (_isScrolled ? AppColors.darkNav.withValues(alpha: 0.95) : Colors.transparent)
        : (_isScrolled ? AppColors.lightNav.withValues(alpha: 0.95) : Colors.transparent);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            border: _isScrolled ? Border(bottom: BorderSide(color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE2E8F0))) : null,
          ),
          child: Row(
            children: [
              Icon(Icons.code, color: AppColors.accent, size: 24),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SiteText('navSiteName', fallback: 'صالح الحودي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
                  SiteText('navTagline', fallback: 'موقع صالح الحودي', style: TextStyle(fontSize: 10, color: AppColors.accent, fontFamily: 'monospace')),
                ],
              ),
              const Spacer(),
              if (MediaQuery.of(context).size.width > 768)
                ...List.generate(sections.length, (i) => _NavItem(label: sections[i], field: sectionFields[i], isDark: isDark, onTap: () => _scrollTo(i))),
              _ThemeToggle(isDark: isDark),
              if (MediaQuery.of(context).size.width <= 768)
                IconButton(
                  icon: Icon(_isMobileOpen ? Icons.close : Icons.menu, color: isDark ? Colors.white : AppColors.lightTextPrimary),
                  onPressed: () => setState(() => _isMobileOpen = !_isMobileOpen),
                ),
            ],
          ),
        ),
        _SocialBar(isDark: isDark),
      ],
    );
  }
}

class _SocialBar extends StatelessWidget {
  final bool isDark;
  const _SocialBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('social_links').orderBy('order').snapshots(),
      builder: (ctx, snap) {
        final items = snap.data?.docs ?? [];
        if (!snap.hasData || items.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: items.map((doc) => _SocialBadge(data: doc.data() as Map<String, dynamic>, isDark: isDark)).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _SocialBadge extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;
  const _SocialBadge({required this.data, required this.isDark});

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: url.isNotEmpty ? () async {
          if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url));
        } : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF0A0A0F) : Colors.white).withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: (isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE2E8F0)).withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon(name), size: 14, color: _color(name)),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 10, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final String field;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({required this.label, required this.field, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextButton(
        onPressed: onTap,
        child: SiteText(field, fallback: label, style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final bool isDark;
  const _ThemeToggle({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
          color: isDark ? AppColors.warning : AppColors.accentPurple, size: 20),
      onPressed: () => context.read<ThemeProvider>().toggleTheme(),
    );
  }
}
