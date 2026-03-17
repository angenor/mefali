import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_b2c/app.dart';

void main() {
  testWidgets('MefaliB2cApp renders phone screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MefaliB2cApp()));
    await tester.pumpAndSettle();

    // L'app demarre sur l'ecran de saisie du telephone (non authentifie).
    expect(find.text('Inscription'), findsOneWidget);
  });
}
