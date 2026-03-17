import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_livreur/app.dart';

void main() {
  testWidgets('MefaliLivreurApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MefaliLivreurApp()));
    expect(find.text('mefali Livreur'), findsOneWidget);
  });
}
