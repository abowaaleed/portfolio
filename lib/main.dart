import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/nav_bar.dart';
import 'widgets/hero_section.dart';
import 'widgets/apps_section.dart';
import 'widgets/tutorials_section.dart';
import 'widgets/news_section.dart';
import 'widgets/blog_section.dart';
import 'widgets/social_section.dart';
import 'widgets/feedback_section.dart';
import 'widgets/footer.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const PortfolioApp(),
    ),
  );
}

class PortfolioApp extends StatelessWidget {
  const PortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'صالح الحودي — Saleh Alhoodi',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const PortfolioPage(),
        );
      },
    );
  }
}

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onSectionTap(int index) {
    final offsets = [0.0, 600.0, 1300.0, 1900.0, 2400.0, 3100.0];
    final target = index < offsets.length ? offsets[index] : 3100.0;
    _scrollController.animateTo(target, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  HeroSection(scrollController: _scrollController),
                  const AppsSection().animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, curve: Curves.easeOut),
                  const TutorialsSection().animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, curve: Curves.easeOut),
                  const NewsSection().animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, curve: Curves.easeOut),
                  const BlogSection().animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, curve: Curves.easeOut),
                  const SocialSection().animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, curve: Curves.easeOut),
                  const FeedbackSection().animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, curve: Curves.easeOut),
                  const FooterSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: NavBar(onSectionTap: _onSectionTap, scrollController: _scrollController),
            ),
          ],
        ),
      ),
    );
  }
}
