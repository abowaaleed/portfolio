import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

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
    final offsets = [0.0, 600.0, 1300.0, 1900.0, 2400.0, 3100.0];
    final target = index < offsets.length ? offsets[index] : 3100.0;
    widget.scrollController.animateTo(target, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    setState(() => _isMobileOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark
        ? (_isScrolled ? AppColors.darkNav.withValues(alpha: 0.95) : Colors.transparent)
        : (_isScrolled ? AppColors.lightNav.withValues(alpha: 0.95) : Colors.transparent);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        border: _isScrolled ? Border(bottom: BorderSide(color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE2E8F0))) : null,
      ),
      child: Row(
        children: [
          Icon(Icons.code, color: AppColors.accent, size: 28),
          const SizedBox(width: 10),
          Text('صالح الحودي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary)),
          const Spacer(),
          if (MediaQuery.of(context).size.width > 768)
            ...List.generate(sections.length, (i) => _NavItem(
              label: sections[i],
              isDark: isDark,
              onTap: () => _scrollTo(i),
            )),
          _ThemeToggle(isDark: isDark),
          if (MediaQuery.of(context).size.width <= 768)
            IconButton(
              icon: Icon(_isMobileOpen ? Icons.close : Icons.menu, color: isDark ? Colors.white : AppColors.lightTextPrimary),
              onPressed: () => setState(() => _isMobileOpen = !_isMobileOpen),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({required this.label, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextButton(
        onPressed: onTap,
        child: Text(label, style: TextStyle(
          fontSize: 14,
          color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
        )),
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
          color: isDark ? AppColors.warning : AppColors.accentPurple),
      onPressed: () => context.read<ThemeProvider>().toggleTheme(),
    );
  }
}
