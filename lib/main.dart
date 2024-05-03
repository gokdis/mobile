import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gokdis/user/shopping_list.dart';
import 'package:provider/provider.dart';
import 'package:gokdis/ble/barcode_reader.dart';
import 'package:gokdis/user/special_offer.dart';
import 'package:gokdis/ble/asd.dart'; // Check if needed.
import 'user/login.dart';
import 'package:gokdis/ble/global_variables.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<Global>(
      create: (context) => Global(),
      child: MaterialApp(
        title: 'My Application',
        home: LoginPage(), 
      ),
    );
  }
}

class MainLayout extends StatefulWidget {
  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    BLEScannerWidget(),
    SpecialOffer(),
    BarcodeReader(), 
    ShoppingListWidget()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      color: Color(0xFF333366),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.map, color: Colors.white),
            onPressed: () => _onItemTapped(0),
          ),
          IconButton(
            icon: Icon(Icons.campaign, color: Colors.white),
            onPressed: () => _onItemTapped(1),
          ),
          IconButton(
            icon: Icon(Icons.barcode_reader, color: Colors.white),
            onPressed: () => _onItemTapped(2),
          ),
           IconButton(
            icon: Icon(Icons.shopping_bag, color: Colors.white),
            onPressed: () => _onItemTapped(3),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
