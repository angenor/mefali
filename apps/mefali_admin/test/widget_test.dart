import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_admin/app.dart';

void main() {
  testWidgets('MefaliAdminApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MefaliAdminApp(),
      ),
    );
    expect(find.text('mefali Admin'), findsOneWidget);
  });
}
