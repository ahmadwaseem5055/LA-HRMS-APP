import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/main.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    // Verify that Login text is visible
    expect(find.text('Login'), findsOneWidget);
  });
}
