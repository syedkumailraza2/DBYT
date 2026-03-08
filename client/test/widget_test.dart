import 'package:flutter_test/flutter_test.dart';
import 'package:client/main.dart';

void main() {
  testWidgets('App loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DBYTApp());

    // Verify that the splash screen loads with the DBYT logo text
    expect(find.text('DBYT'), findsOneWidget);
  });
}
