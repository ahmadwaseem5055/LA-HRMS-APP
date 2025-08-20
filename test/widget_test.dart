import 'package:flutter_test/flutter_test.dart';
import 'package:odoo_employee/main.dart';


void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    // Load the root widget of your app
    await tester.pumpWidget(const MyApp());

    // Verify that MyApp actually built
    expect(find.byType(MyApp), findsOneWidget);
  });
}
