import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/main.dart';

void main() {
  testWidgets('Admin app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AdminApp());
    expect(find.byType(AdminApp), findsOneWidget);
  });
}
