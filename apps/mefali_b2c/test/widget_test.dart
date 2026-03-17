import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_b2c/app.dart';

void main() {
  testWidgets('MefaliB2cApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MefaliB2cApp()));
    expect(find.text('mefali B2C'), findsOneWidget);
  });
}
