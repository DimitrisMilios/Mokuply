import 'package:flutter_test/flutter_test.dart';
import 'package:storecraft_studio/main.dart';

void main() {
  testWidgets('StoreCraft Studio smoke test', (WidgetTester tester) async {
    // Build StoreCraftStudioApp and trigger a frame.
    await tester.pumpWidget(const StoreCraftStudioApp());

    // Verify title text exists
    expect(find.text('StoreCraft Studio'), findsOneWidget);
  });
}
