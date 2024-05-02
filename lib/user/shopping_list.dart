import 'package:epitaph_ips/epitaph_ips/buildings/point.dart';
import 'package:flutter/material.dart';
import 'package:gokdis/user/special_offer.dart';
import 'package:gokdis/ble/barcode_reader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:gokdis/settings.dart';
import '../ble/asd.dart';
import 'package:gokdis/ble/global_variables.dart';

class BeaconProvider with ChangeNotifier {
  List<dynamic> _beaconData = [];

  List<dynamic> get beaconData => _beaconData;

  void setBeaconData(List<dynamic> beaconData) {
    _beaconData = beaconData;
    notifyListeners();
  }
}

class ShoppingListWidget extends StatefulWidget {
  @override
  ShoppingListWidgetState createState() => ShoppingListWidgetState();
}

class ShoppingListWidgetState extends State<ShoppingListWidget> {
  List<dynamic> beaconData = [];
  late Set<String> uniqueAisles;


  @override
  void initState() {
    super.initState();
    getBeacons();
    getSections();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final global = Provider.of<Global>(context, listen: false);
      global.getAislesFromTXT();
    });
    uniqueAisles = Provider.of<Global>(context, listen: false).uniqueAisles;

  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

 @override
Widget build(BuildContext context) {
  return Consumer<Global>(
    builder: (context, global, child) {
      List<String> uniqueAislesList = global.uniqueAisles.toList();
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              }),
          title: Text('Shopping List'),
          backgroundColor: Color(0xFFFFA500),
        ),
        drawer: Drawer(
          child: ListView.builder(
            itemCount: uniqueAislesList.length,
            itemBuilder: (BuildContext context, int index) {
              var aisleId = uniqueAislesList[index];
              return ListTile(
                title: Text(aisleId),
                onTap: () {
                  _scaffoldKey.currentState?.closeDrawer();
           
                  setState(() {
                    for (var aisle in global.aisleCoordinates) { 
                      if (aisle.name == aisleId) {
                      }
                    }
                  });
                },
              );
            },
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      );
    },
  );
}


  // Shopping list functions

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          ElevatedButton(
            onPressed: () {
              navigateToMap();
            },
            child: Icon(Icons.map),
            style: ElevatedButton.styleFrom(
              shape: CircleBorder(),
              padding: EdgeInsets.all(16),
              backgroundColor: Colors.orange,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              navigateToSpecialOffer();
            },
            child: Icon(Icons.campaign),
            style: ElevatedButton.styleFrom(
              shape: CircleBorder(),
              padding: EdgeInsets.all(16),
              backgroundColor: Colors.orange,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              navigateToBarcodeReader();
            },
            child: Icon(Icons.barcode_reader),
            style: ElevatedButton.styleFrom(
              shape: CircleBorder(),
              padding: EdgeInsets.all(16),
              backgroundColor: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  // get beacons from server

  Future<void> getBeacons() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String url = Settings.instance.getUrl('beacon');
    String? email = prefs.getString('email');
    String? password = prefs.getString('password');
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$email:$password'));

    final Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      'Authorization': basicAuth,
    };

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: requestHeaders,
      );

      if (response.statusCode == 200) {
        beaconData = jsonDecode(response.body);
        Provider.of<BeaconProvider>(context, listen: false)
            .setBeaconData(beaconData);
        //   print('before update : $beaconData');
        updateGlobalBeaconCoordinates(beaconData);
        print('After updat e: ${Settings.globalBeaconCoordinates}');
      } else {
        print("Failed to fetch data. Status code: ${response.statusCode}");
      }
    } catch (error) {
      print("Error occurred while fetching data: $error");
    }
  }

  void updateGlobalBeaconCoordinates(List<dynamic> beaconData) {
    for (var beacon in beaconData) {
      // String id = beacon['id'];
      String mac = beacon['mac'].toString().toUpperCase();
      double x = beacon['x'].toDouble();
      double y = beacon['y'].toDouble();
      Settings.globalBeaconCoordinates[mac] = Point(x, y);
    }
  }

  Future<void> getSections() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = Settings.instance.getUrl('section');
    String? email = prefs.getString('email');
    String? password = prefs.getString('password');
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$email:$password'));

    final Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      'Authorization': basicAuth,
    };

    try {
      final response = await http.get(Uri.parse(url), headers: requestHeaders);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print("sections : $data");
      } else {
        print("Failed to fetch data. Status code: ${response.statusCode}");
      }
    } catch (error) {
      print("Error occurred while fetching data: $error");
    }
  }

  // Navigation functions

  void navigateToMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BLEScannerWidget(),
      ),
    );
  }

  void navigateToSpecialOffer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpecialOffer(),
      ),
    );
  }

  void navigateToBarcodeReader() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeReader(),
      ),
    );
  }
}
