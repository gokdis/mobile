import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:gokdis/settings.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epitaph_ips/epitaph_ips/buildings/point.dart';
import 'package:flutter/material.dart';
import 'asd.dart';

class Global extends ChangeNotifier {
  List<Aisle> _aisleCoordinates = [];
  Set<String> _uniqueAisles = Set();
  Map<String, Map<String, String>> _productList = {};
  Map<String, String> _sectionList = {};
  Map<String, Point> _beaconCoordinates = {};
  Map<String, dynamic> _recommendedItems = {};

  bool dataLoaded = false;

  // getter methods
  Set<String> get uniqueAisles => _uniqueAisles;
  List<Aisle> get aisleCoordinates => _aisleCoordinates;
  Map<String, Map<String, String>> get productList => _productList;
  Map<String, String> get sectionList => _sectionList;
  Map<String, Point> get beaconCoordinates => _beaconCoordinates;
  Map<String, dynamic> get recommendedItems => _recommendedItems;

  Future<void> highlightAisle(
      String productName, Map<String, Map<String, dynamic>> cart) async {
    String? sectionId;
    productList.forEach((productId, productInfo) {
      if (productInfo['name'] == productName) {
        sectionId = productInfo['sectionId'];
      }
    });

    String sectionName = "";
    
    //TODO BUGFIX: If more than one product is added to shopping list and only one removed, it removes aisle highlight despite still having product belonging to that section
    
    sectionName = sectionList[sectionId]!;
    for (var aisle in aisleCoordinates) {
      if (aisle.name.toLowerCase() == sectionName.toLowerCase()) {
        if (cart.containsKey(productName)) {
          aisle.visible = true;
        } else {
          aisle.visible = false;
        }
      }
    }

    notifyListeners();
  }

  List<Map<String, String>> getProductsBySection(String sectionId) {
    return productList.entries
        .where((entry) => entry.value['sectionId'] == sectionId)
        .map((entry) => entry.value)
        .toList();
  }

  Future<void> getAislesFromTXT() async {
    try {
      String textasset = "assets/cells.json";
      String text = await rootBundle.loadString(textasset);

      List<dynamic> jsonResponse = jsonDecode(text);

      updateAisle(jsonResponse);
    } catch (error) {
      print("Error occurred while reading data from file: $error");
    }
  }

  void updateAisle(List<dynamic> aisleData) {
    List<Aisle> newAisles = [];

    for (var aisle in aisleData) {
      String id = aisle['name'].toString();
      double x = aisle['x'].toDouble();
      double y = aisle['y'].toDouble();
      String color = aisle['color'].toString();

      newAisles.add(Aisle(id, Point(x, y), color: color));
      if (!_uniqueAisles.contains(id)) {
        _uniqueAisles.add(id);
      }
    }
    _aisleCoordinates = newAisles;
    notifyListeners();
  }

  Future<void> getProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = Settings.instance.getUrl('product');
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
        final List<dynamic> data = jsonDecode(response.body);
        updateProductList(data);
      } else {
        print("Failed to fetch data. Status code: ${response.statusCode}");
      }
    } catch (error) {
      print("Error occurred while fetching data: $error");
    }
  }

  void updateProductList(List<dynamic> productData) {
    Map<String, Map<String, String>> newProductList = {};
    for (var product in productData) {
      if (product is Map<String, dynamic>) {
        String id = product['id'];
        newProductList[id] = {
          'name': product['name'],
          'price': product['price'].toString(),
          'description': product['description'],
          'stock': product['stock'].toString(),
          'sectionId': product['sectionId'].toString()
        };
      }
    }
    _productList = newProductList;
    print(newProductList.entries.length);
    notifyListeners();
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
        final section = json.decode(response.body);
        updateSectionList(section);
      } else {
        print("Failed to fetch data. Status code: ${response.statusCode}");
      }
    } catch (error) {
      print("Error occurred while fetching data: $error");
    }
  }

  void updateSectionList(List<dynamic> sectionData) {
    Map<String, String> newSectionList = {};
    for (var section in sectionData) {
      String id = section['id'];
      String name = section['name'];

      newSectionList[id] = name;
    }
    _sectionList = newSectionList;
    notifyListeners();
  }

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
      final response = await http.get(Uri.parse(url), headers: requestHeaders);
      if (response.statusCode == 200) {
        final List<dynamic> beaconData = jsonDecode(response.body);
        updateGlobalBeaconCoordinates(beaconData);
      } else {
        print("Failed to fetch data. Status code: ${response.statusCode}");
      }
    } catch (error) {
      print("Error occurred while fetching data: $error");
    }
  }

  void updateGlobalBeaconCoordinates(List<dynamic> beaconData) {
    for (var beacon in beaconData) {
      if (beacon is Map<String, dynamic>) {
        String mac = beacon['mac'].toString().toUpperCase();
        double x = double.tryParse(beacon['x'].toString()) ?? 0;
        double y = double.tryParse(beacon['y'].toString()) ?? 0;

        _beaconCoordinates[mac] = Point(x, y);
      }
    }
    notifyListeners();
  }

  Future<void> getRecommandationItem() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? email = prefs.getString('email');
    String url = Settings.instance.getRecommandationUrl(email!);
    print(url);

    final Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
      'Accept': 'application/json'
    };

    try {
      final response = await http.get(Uri.parse(url), headers: requestHeaders);
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        _recommendedItems = data;
        notifyListeners();
        print(_recommendedItems);
      } else {
        print("Failed to fetch data. Status code: ${response.statusCode}");
      }
    } catch (error) {
      print("Error occurred while fetching data: $error");
    }
  }

  Future<void> loadData() async {
    if (!dataLoaded) {
      await getAislesFromTXT();
      await getProducts();
      await getSections();
      await getBeacons();
      await getRecommandationItem();
      dataLoaded = true;
    }
  }
}
