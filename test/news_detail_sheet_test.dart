import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saleh_alhoodi_portfolio/widgets/news_detail_sheet.dart';

void main() {
  // 1x1 PNG صغيرة سليمة لاختبار صورة base64.
  const tinyPng =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

  testWidgets('فتح البطاقة يعرض التفاصيل وزر المصدر ويطلق الرابط', (tester) async {
    final launched = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (call) async {
        if (call.method == 'canLaunch') return true;
        if (call.method == 'launch') {
          final args = (call.arguments as Map).cast<String, dynamic>();
          launched.add(args['url'] as String);
          return true;
        }
        return null;
      },
    );

    final data = <String, dynamic>{
      'title': 'قفزة تاريخية.. قيمة آبل السوقية تتجاوز 5 تريليونات دولار',
      'content': 'سطر أول\nسطر ثان\nسطر ثالث\nسطر رابع',
      'description': 'وصف احتياطي',
      'source': 'أخبار التقنية (aitnews)',
      'url': 'https://aitnews.com/example/',
      'link': 'https://aitnews.com/example/',
      'imageBase64': 'data:image/png;base64,$tinyPng',
    };

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => NewsDetailSheet(data: data, isDark: false),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('قفزة تاريخية.. قيمة آبل السوقية تتجاوز 5 تريليونات دولار'), findsOneWidget);
    expect(find.text('سطر أول\nسطر ثان\nسطر ثالث\nسطر رابع'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('اقرأ الخبر كاملاً من المصدر الأصلي'),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('اقرأ الخبر كاملاً من المصدر الأصلي'), findsOneWidget);
    await tester.tap(find.text('اقرأ الخبر كاملاً من المصدر الأصلي'));
    await tester.pumpAndSettle();

    expect(launched, contains('https://aitnews.com/example/'));
  });

  testWidgets('إخفاء زر المصدر عند غياب الرابط', (tester) async {
    final data = <String, dynamic>{
      'title': 'خبر بدون رابط',
      'content': 'لا يوجد رابط أصلي لهذا الخبر.',
      'source': 'أخبار التقنية',
    };

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => NewsDetailSheet(data: data, isDark: true),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('خبر بدون رابط'), findsOneWidget);
    expect(find.text('اقرأ الخبر كاملاً من المصدر الأصلي'), findsNothing);
  });
}
