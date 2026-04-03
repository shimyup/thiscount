import 'package:flutter_test/flutter_test.dart';
import 'package:letter_go/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GlobalDriftApp(initialLoggedIn: false));
    expect(find.byType(GlobalDriftApp), findsOneWidget);
  });
}
