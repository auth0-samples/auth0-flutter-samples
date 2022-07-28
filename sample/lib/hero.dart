import 'package:flutter/material.dart';
import 'constants.dart';

class HeroWidget extends StatelessWidget {
  const HeroWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        margin: const EdgeInsets.only(bottom: margin),
        child: Image.asset('images/logo.png', width: 24),
      ),
      Expanded(
          child: Container(
              margin: const EdgeInsets.all(margin),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Flutter'),
                    const Text('Sample App'),
                  ])))
    ]);
  }
}
