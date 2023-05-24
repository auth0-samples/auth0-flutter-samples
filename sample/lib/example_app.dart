import 'dart:developer';
import 'dart:html';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'constants.dart';
import 'hero.dart';
import 'user.dart';

class ExampleApp extends StatefulWidget {
  // final Auth0? auth0;
  final Auth0Web? auth0Web;

  const ExampleApp({this.auth0Web, final Key? key}) : super(key: key);

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  dynamic _user;

  late Auth0Web auth0Web;

  @override
  void initState() {
    super.initState();
    auth0Web =
        Auth0Web(dotenv.env['AUTH0_DOMAIN']!, dotenv.env['AUTH0_CLIENT_ID']!);

    if (kIsWeb) {
      auth0Web.onLoad().then((final credentials) {
        _user = credentials?.user;
      });
    }
  }

  Future<void> login() async {
    // var credentials = await auth0
    //     .webAuthentication(scheme: dotenv.env['AUTH0_CUSTOM_SCHEME'])
    //     .login();
    final popup = window.open('', '', 'width=400,height=800');

    final c = await auth0Web.loginWithPopup(popupWindow: popup);

    setState(() {
      _user = c.user;
      inspect(_user);
    });

    // setState(() {
    //   _user = credentials.user;
    // });
  }

  Future<void> logout() async {
    // await auth0
    //     .webAuthentication(scheme: dotenv.env['AUTH0_CUSTOM_SCHEME'])
    //     .logout();

    return auth0Web.logout();

    // setState(() {
    //   _user = null;
    // });
  }

  @override
  Widget build(final BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          body: Padding(
        padding: const EdgeInsets.only(
          top: padding,
          bottom: padding,
          left: padding / 2,
          right: padding / 2,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
              child: Column(children: [
            _user != null
                ? UserWidget(user: _user)
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
    );
  }
}
