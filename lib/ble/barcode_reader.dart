import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:gokdis/ble/global_variables.dart';
import 'package:gokdis/settings.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BarcodeReader extends StatefulWidget {
  @override
  BarcodeReaderState createState() => BarcodeReaderState();
}

class BarcodeReaderState extends State<BarcodeReader> {
  String _scanBarcode = 'Unknown';
  List<String> _basketItems = [];
  List<Map<String, dynamic>> itemsToSend = [];

  Map<String, Map<String, String>> _productList = {};
  @override
  void initState() {
    super.initState();
  }

  Future<void> scanBarcodeNormal() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);
      print(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _scanBarcode = barcodeScanRes;
      _basketItems.add(barcodeScanRes);
    });
  }

  String generateRandomUuid() {
    final random = Random();
    final hexChars = '0123456789abcdef';
    final buffer = StringBuffer();
    for (int i = 0; i < 32; i++) {
      buffer.write(hexChars[random.nextInt(16)]);
    }

    return buffer
        .toString()
        .replaceRange(8, 8, '-')
        .replaceRange(13, 13, '-')
        .replaceRange(18, 18, '-')
        .replaceRange(23, 23, '-');
  }

  Future<void> sendBasketItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
    String? password = prefs.getString('password');

    String url = Settings.instance.getUrl('order');
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$email:$password'));
    List<Map<String, dynamic>> itemsToSend = [];

    for (String itemId in _basketItems) {
      var product = _productList[itemId];
      if (product != null) {
        itemsToSend.add({
          'id': generateRandomUuid(),
          'personEmail': email,
          'productId': itemId,
          'description': product['description'] ?? 'No description available',
          'quantity': product['stock'] ?? 0,
          'time': DateTime.now().toIso8601String()
        });
      }
    }

    for (var item in itemsToSend) {
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-type': 'application/json',
            'Accept': 'application/json',
            'Authorization': basicAuth,
          },
          body: jsonEncode(item),
        );

        if (response.statusCode == 200) {
          print("Item sent successfully: ${item['productId']}");
        } else {
          print("Failed to send item. Status code: ${response.statusCode}");
        }
      } catch (error) {
        print("Error occurred while sending item: $error");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Global>(
      builder: (context, model, child) {
        _productList = Provider.of<Global>(context, listen: false).productList;
        return MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Barcode Scan',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.deepOrange,
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.shopping_cart),
                  onPressed: () => _showShoppingCartDialog(context),
                ),
              ],
            ),
            body: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  ElevatedButton.icon(
                    icon: Icon(Icons.camera_alt, color: Colors.white),
                    label: Text('Start Barcode Scan'),
                    onPressed: scanBarcodeNormal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 24.0),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                  ),
                  Expanded(
                    child: _buildProductList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductList() {
    return ListView.builder(
      itemCount: _basketItems.length,
      itemBuilder: (context, index) {
        var item = _basketItems[index];
        var product =
            _productList[item] ?? {'name': 'Unknown Product', 'price': '0'};
        return Card(
          elevation: 2.0,
          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: ListTile(
            title: Text(product['name']!,
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Price: \$${product['price']}'),
            leading: Icon(Icons.shopping_basket, color: Colors.orange),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeItemFromBasket(index),
            ),
          ),
        );
      },
    );
  }

  void _showShoppingCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Basket",
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.deepOrange)),
          content: SingleChildScrollView(
            child: ListBody(
              children: _basketItems.map((item) {
                var matchingProduct = _productList[item] ??
                    {'name': 'Unknown Product', 'price': '0'};
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 16, color: Colors.black),
                      children: <TextSpan>[
                        TextSpan(
                            text: matchingProduct['name'],
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: ' - '),
                        TextSpan(
                            text: '\$${matchingProduct['price']}',
                            style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Buy'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                sendBasketItems();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Close'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _removeItemFromBasket(int index) {
    setState(() {
      _basketItems.removeAt(index);
    });
  }
}
