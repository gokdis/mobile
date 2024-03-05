import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ble/ble_scanner.dart';
//import 'user/shopping_list.dart';
import 'user/login.dart';
import 'user/register.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
  BLEScanner bleScanner = BLEScanner();
  //bleScanner.startScan();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage(),
    );
  }
}
