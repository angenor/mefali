import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_admin/app.dart';

void main() {
  testWidgets('MefaliAdminApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MefaliAdminApp());
    expect(find.text('mefali Admin'), findsOneWidget);
  });
}
