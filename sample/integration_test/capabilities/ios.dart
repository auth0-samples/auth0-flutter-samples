import 'dart:io';

final Map<String, dynamic> iosCapabilities = {
  'platformName': 'ios',
  'platformVersion': '15.0',
  'deviceName': 'iPhone 13 Pro',
  'automationName': 'Flutter',
  'reduceMotion': true,
  'app': File('build/ios/iphonesimulator/Runner.app').absolute.path,
};
