import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_b2b/app.dart';

void main() {
  testWidgets('MefaliB2bApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MefaliB2bApp());
    expect(find.text('mefali B2B'), findsOneWidget);
  });
}
