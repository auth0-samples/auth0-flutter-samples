import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'constants.dart';
import 'hero.dart';
import 'user.dart';

class ExampleApp extends StatefulWidget {
  const ExampleApp({final Key? key}) : super(key: key);

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  UserProfile? _user;

  late Auth0 auth0;
  late WebAuthentication webAuth;

  @override
  void initState() {
    super.initState();
    auth0 = Auth0(dotenv.env['AUTH0_DOMAIN']!, dotenv.env['AUTH0_CLIENT_ID']!);
    webAuth = auth0.webAuthentication();
  }

  Future<void> login() async {
    var credentials =
        await webAuth.login(scheme: dotenv.env['AUTH0_CUSTOM_SCHEME']);

    setState(() {
      _user = credentials.user;
    });
  }

  Future<void> logout() async {
    await webAuth.logout(scheme: dotenv.env['AUTH0_CUSTOM_SCHEME']);

    setState(() {
      _user = null;
    });
  }

  @override
  Widget build(final BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          body: CustomScrollView(
        slivers: <Widget>[
          SliverFillRemaining(
              child: Padding(
            padding: const EdgeInsets.only(
                top: padding,
                bottom: padding,
                left: padding / 2,
                right: padding / 2),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                      child: Column(children: [
                    _user != null
                        ? UserWidget(user: _user as UserProfile)
                        : const Expanded(child: HeroWidget())
                  ])),
                  _user != null
                      ? ElevatedButton(
                          onPressed: logout,
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.black),
                          ),
                          child: const Text('Logout'),
                        )
                      : ElevatedButton(
                          onPressed: login,
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.black),
                          ),
                          child: const Text('Login'),
                        )
                ]),
          )),
        ],
      )),
    );
  }
}
