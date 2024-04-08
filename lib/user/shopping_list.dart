import 'package:epitaph_ips/epitaph_ips/buildings/point.dart';
import 'package:flutter/material.dart';
import 'package:gokdis/user/special_offer.dart';
import 'package:gokdis/ble/barcode_reader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:gokdis/settings.dart';

import '../ble/deneme.dart';

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
  TextEditingController _itemController = TextEditingController();
  List<String> _items = [];
  List<dynamic> beaconData = [];

  @override
  void initState() {
    super.initState();
    getBeacons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping List'),
        backgroundColor: Color(0xFFFFA500),
      ),
      body: Column(
        children: [
          _buildAddItemField(),
          _buildItemList(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
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

  Widget _buildAddItemField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _itemController,
              decoration: InputDecoration(
                hintText: 'Enter item',
              ),
            ),
          ),
          SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              _addItem();
            },
            child: Text('Add'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    String newItem = _itemController.text.trim();
    if (newItem.isNotEmpty) {
      setState(() {
        _items.add(newItem);
        _itemController.clear();
      });
    }
  }

  Widget _buildItemList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_items[index]),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _removeItem(index);
              },
            ),
          );
        },
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
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
  // Navigation functions

  void navigateToMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BLEScannerWidget1(),
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
