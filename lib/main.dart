import 'package:flutter/material.dart';
//import 'ble/ble_scanner.dart';
//import 'user/shopping_list.dart';
import 'user/login.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage(),
    );
  }
}
