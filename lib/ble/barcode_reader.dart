import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:gokdis/settings.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BarcodeReader extends StatefulWidget {
  @override
  BarcodeReaderState createState() => BarcodeReaderState();
}

class BarcodeReaderState extends State<BarcodeReader> {
  String _scanBarcode = 'Unknown';
  List<String> _basketItems = [];
  List<Map<String, dynamic>> itemsToSend = [];

  late String prodcuts;
  Map<String, Map<String, String>> _productList = {};
  @override
  void initState() {
    super.initState();
    getProducts();
  }

  Future<void> startBarcodeScanStream() async {
    FlutterBarcodeScanner.getBarcodeStreamReceiver(
            '#ff6666', 'Cancel', true, ScanMode.BARCODE)!
        .listen((barcode) {
      print(barcode);
      if (!mounted) return;
      setState(() {
        _basketItems.add(barcode);
      });
    });
  }

  Future<void> scanQR() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.QR);
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
        final data = json.decode(response.body);
        final List<dynamic> products = data['content'];
        _productList = {
          for (var product in products)
            product['id']: {
              'name': product['name'],
              'price': product['price'].toString(),
              'description': product['description'],
              'stock': product['stock'].toString(),
            }
        };
        print(_productList);
        print("Product list loaded successfully");
      } else {
        print("Failed to fetch data. Status code: ${response.statusCode}");
      }
    } catch (error) {
      print("Error occurred while fetching data: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Barcode Scan'),
          backgroundColor: Color(0xFFFFA500),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.shopping_cart),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Basket"),
                      content: SingleChildScrollView(
                        child: ListBody(
                          children: _basketItems.map((item) {
                            var matchingProduct = _productList[item] ??
                                {'name': 'Unknown Product', 'price': '0'};
                            return Text(
                                '${matchingProduct['name']} - \$${matchingProduct['price']}');
                          }).toList(),
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text('Buy'),
                          onPressed: () {
                            sendBasketItems();
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text('Close'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
        body: Builder(builder: (BuildContext context) {
          return Container(
            alignment: Alignment.center,
            child: Flex(
              direction: Axis.vertical,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () => scanBarcodeNormal(),
                  child: Text('Start barcode scan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => scanQR(),
                  child: Text('Start QR scan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => startBarcodeScanStream(),
                  child: Text('Start barcode scan stream'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _basketItems.length,
                    itemBuilder: (context, index) {
                      var item = _basketItems[index];
                      var product = _productList[item] ??
                          {'name': 'Unknown Product', 'price': '0'};
                      return ListTile(
                        title: Text('${product['name']}'),
                        subtitle: Text('Price: \$${product['price']}'),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
