import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:gokdis/ble/asd.dart';  
import 'user/login.dart';
import 'package:gokdis/user/shopping_list.dart';
import 'package:gokdis/ble/global_variables.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BeaconProvider()),
        ChangeNotifierProvider(create: (context) => Global()), 
      ],
      child: MaterialApp(
        home: LoginPage(),
      ),
    );
  }
}
