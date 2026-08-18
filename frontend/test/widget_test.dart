import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('BBJOMS app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const BBJOMSApp());

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Factory Overview'), findsOneWidget);
  });
}