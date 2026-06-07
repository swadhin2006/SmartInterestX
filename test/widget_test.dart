import 'package:flutter_test/flutter_test.dart';
import 'package:smart_interest_x/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartInterestXApp());
    expect(find.byType(SmartInterestXApp), findsOneWidget);
  });
}
