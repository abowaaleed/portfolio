import 'package:flutter_test/flutter_test.dart';
import 'package:saleh_alhoodi_portfolio/main.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const PortfolioApp());
    expect(find.text('صالح الحودي'), findsWidgets);
  });
}
