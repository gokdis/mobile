import 'package:flutter/material.dart';
import 'ble/ble_scanner.dart';
import 'user/shopping_list.dart';
import 'user/login.dart';
import 'user/register.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final BLEScanner blEscanner = BLEScanner();

  @override
  Widget build(BuildContext context) {
    // blEscanner.startScan();
    return MaterialApp(
      home: RegistrationPage(),
    );
  }
}
