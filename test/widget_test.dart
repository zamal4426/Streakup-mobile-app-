import 'package:flutter_test/flutter_test.dart';
import 'package:streakup/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const StreakUpApp());
    expect(find.text('StreakUp'), findsOneWidget);
    expect(find.text('Build Better Habits'), findsOneWidget);
  });
}
