import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'services/firebase_service.dart';
import 'services/firestore_service.dart';
import 'widgets/nav_bar.dart';
import 'widgets/hero_section.dart';
import 'widgets/apps_section.dart';
import 'widgets/tutorials_section.dart';
import 'widgets/news_section.dart';
import 'widgets/blog_section.dart';
import 'widgets/social_section.dart';
import 'widgets/feedback_section.dart';
import 'widgets/footer.dart';
import 'admin/admin_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppLoader());
}

class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    try {
      await FirebaseService.init();
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0A0A0F),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.code, color: Color(0xFF00D4FF), size: 48),
                const SizedBox(height: 24),
                const Text('صالح الحودي', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Saleh Alhoodi', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 14, fontFamily: 'monospace')),
                const SizedBox(height: 32),
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00D4FF))),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text('Firebase Error: $_error', style: const TextStyle(color: Colors.redAccent, fontSize: 12), textAlign: TextAlign.center),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const PortfolioApp(),
    );
  }
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
          routes: {
            '/admin': (_) => const AdminDashboard(),
          },
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
  bool _showScrollBtn = false;

  @override
  void initState() {
    super.initState();
    FirestoreService.trackPageView().catchError((_) {});
    _scrollController.addListener(() {
      final show = _scrollController.offset > 500;
      if (show != _showScrollBtn) setState(() => _showScrollBtn = show);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('settings').doc('profile').snapshots(),
        builder: (ctx, snap) {
          final data = snap.data?.data() as Map<String, dynamic>?;
          final bgB64 = data?['backgroundImageBase64'] as String?;
          return Stack(
            children: [
              if (bgB64 != null && bgB64.isNotEmpty)
                Positioned.fill(
                  child: Image(image: MemoryImage(base64Decode(bgB64.split(',').last)), fit: BoxFit.cover),
                ),
              Positioned.fill(
                child: Container(color: (isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC)).withValues(alpha: 0.65)),
              ),
              SafeArea(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        children: [
                          HeroSection(scrollController: _scrollController),
                          const _SuggestionsCarousel(),
                          const AppsSection(),
                          const TutorialsSection(),
                          const NewsSection(),
                          const BlogSection(),
                          const SocialSection(),
                          const FeedbackSection(),
                          const FooterSection(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: NavBar(scrollController: _scrollController),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showScrollBtn)
            FloatingActionButton.small(
              heroTag: 'scroll_to_bottom',
              onPressed: () => _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              ),
              backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
              child: Icon(Icons.keyboard_arrow_down, color: isDark ? Colors.white : AppColors.lightTextPrimary),
            ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            heroTag: 'admin_btn',
            onPressed: () => Navigator.pushNamed(context, '/admin'),
            backgroundColor: AppColors.accentPurple,
            child: const Icon(Icons.admin_panel_settings, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SuggestionsCarousel extends StatefulWidget {
  const _SuggestionsCarousel();

  @override
  State<_SuggestionsCarousel> createState() => _SuggestionsCarouselState();
}

class _SuggestionsCarouselState extends State<_SuggestionsCarousel> {
  int _current = 0;
  Timer? _timer;
  List<QueryDocumentSnapshot> _items = [];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoScroll(int count) {
    _timer?.cancel();
    if (count <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() => _current = (_current + 1) % count);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('apps').orderBy('isPinned', descending: true).snapshots(),
      builder: (ctx, snap) {
        _items = snap.data?.docs ?? [];
        if (!snap.hasData || _items.isEmpty) return const SizedBox.shrink();
        _startAutoScroll(_items.length);
        final data = _items[_current].data() as Map<String, dynamic>;
        final url = data['url'] as String? ?? '';
        final img = data['imageBase64'] as String?;
        return Container(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.explore, size: 13, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text('مقترحة لك', style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: url.isNotEmpty ? () async {
                  if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url));
                } : null,
                child: Container(
                  width: 240,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF0A0A0F) : Colors.white).withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE2E8F0)).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      if (img != null && img.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(width: 28, height: 28,
                            decoration: BoxDecoration(
                              image: DecorationImage(image: MemoryImage(base64Decode(img.split(',').last)), fit: BoxFit.cover),
                            ),
                          ),
                        )
                      else
                        Icon(Icons.picture_as_pdf, size: 18, color: AppColors.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(data['name'] as String? ?? '',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.lightTextPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.arrow_back_ios, size: 12, color: AppColors.accent),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_items.length, (i) => Container(
                  width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _current ? AppColors.accent : (isDark ? AppColors.textSecondary.withValues(alpha: 0.3) : AppColors.lightTextSecondary.withValues(alpha: 0.3)),
                  ),
                )),
              ),
            ],
          ),
        );
      },
    );
  }
}
