import 'package:flutter/material.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'example_app.dart';

void main() async {
  enableFlutterDriverExtension();
  
  await dotenv.load();

  runApp(const ExampleApp());
}

