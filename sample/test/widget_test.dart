// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample/example_app.dart';

Future<void> main() async {
  dotenv.testLoad(fileInput: '''AUTH0_DOMAIN=foo
AUTH0_CLIENT_ID=bar
''');
  testWidgets('runs the app', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ExampleApp());

    // Verify that our counter starts at 0.
    expect(find.text('Auth0 Example'), findsOneWidget);
  });
}
