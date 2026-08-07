import 'package:flutter_test/flutter_test.dart';
import 'package:mocuply/app.dart';

void main() {
  testWidgets('Mocuply smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MocuplyApp());
    expect(find.text('Mocuply'), findsOneWidget);
  });
}
