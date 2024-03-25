import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'user/login.dart';
import 'package:gokdis/user/shopping_list.dart';
import 'package:provider/provider.dart';
import 'ble/ble_scanner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(MyApp());
  BLEScanner bleScanner = BLEScanner();
  bleScanner.startScan();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BeaconProvider(),
      child: MaterialApp(
        home: LoginPage(),
      ),
    );
  }
}
