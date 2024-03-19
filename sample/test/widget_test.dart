// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:auth0_flutter/auth0_flutter.dart';
// Needs to be exported from auth0_flutter
// ignore: depend_on_referenced_packages
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sample/example_app.dart';

import 'widget_test.mocks.dart';

@GenerateMocks([Auth0, WebAuthentication])
void main() async {
  dotenv.testLoad(fileInput: '''AUTH0_DOMAIN=foo
AUTH0_CLIENT_ID=bar
''');
  final mockedWebAuth = MockWebAuthentication();
  final mocked = MockAuth0();

  testWidgets('can execute login flow',
      (WidgetTester tester) async {
    when(mocked.webAuthentication()).thenReturn(mockedWebAuth);
    when(mockedWebAuth.login(
      audience: anyNamed('audience'),
      invitationUrl: anyNamed('invitationUrl'),
      organizationId: anyNamed('organizationId'),
      redirectUrl: anyNamed('redirectUrl'),
      scopes: anyNamed('scopes'),
      parameters: anyNamed('parameters'),
      useHTTPS: anyNamed('useHTTPS'),
      useEphemeralSession: anyNamed('useEphemeralSession'),
      idTokenValidationConfig: anyNamed('idTokenValidationConfig'),
    )).thenAnswer((_) => Future.value(Credentials.fromMap({
          'accessToken': 'accessToken',
          'idToken': 'idToken',
          'refreshToken': 'refreshToken',
          'expiresAt': DateTime.now().toIso8601String(),
          'scopes': ['a'],
          'userProfile': {'sub': '123', 'name': 'John Doe'},
          'tokenType': 'Bearer'
        })));

    await tester.pumpWidget(ExampleApp(auth0: mocked));

    final loginButton = find.text('Login');

    // Shows login button when not logged in
    expect(find.text('Login'), findsOneWidget);
    // Does not show logout button when not logged in
    expect(find.text('Logout'), findsNothing);

    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    verify(mockedWebAuth.login(
      audience: anyNamed('audience'),
      invitationUrl: anyNamed('invitationUrl'),
      organizationId: anyNamed('organizationId'),
      redirectUrl: anyNamed('redirectUrl'),
      scopes: anyNamed('scopes'),
      parameters: anyNamed('parameters'),
      useHTTPS: anyNamed('useHTTPS'),
      useEphemeralSession: anyNamed('useEphemeralSession'),
      idTokenValidationConfig: anyNamed('idTokenValidationConfig'),
    )).called(1);

    final logoutButton = find.text('Logout');

    // Shows logout button when logged in
    expect(find.text('Logout'), findsOneWidget);
    // Does not show Login button when logged in
    expect(find.text('Login'), findsNothing);

    // Shows profile information when logged in
    expect(find.text('Email'), findsOneWidget);

    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    verify(mockedWebAuth.logout(
      useHTTPS: anyNamed('useHTTPS'),
      returnTo: anyNamed('returnTo'),
    )).called(1);

    // Shows login button when logged out
    expect(find.text('Login'), findsOneWidget);
    // Does not show Logout button when logged out
    expect(find.text('Logout'), findsNothing);
  });
}
