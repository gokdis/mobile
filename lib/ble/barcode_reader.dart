import 'dart:async';
import 'dart:convert';
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
  late String prodcuts;
  List<Map<String, String>> _productList = [];
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
      final response = await http.get(
        Uri.parse(url),
        headers: requestHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseBody = json.decode(response.body);
        _productList = responseBody
            .map((product) => {
                  'id': product['id'].toString(),
                  'name': product['name'].toString(),
                  'price': product['price'].toString(),
                })
            .toList();
        print(_productList);
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
              title: const Text('Barcode scan'),
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
                                var matchingProduct = _productList.firstWhere(
                                  (product) => product['id'] == item,
                                  orElse: () => {
                                    'name': 'Unknown Product',
                                    'price': '0'
                                  }, 
                                );
                               
                                return Text(
                                    '${matchingProduct['name']} - ${matchingProduct['price']}');
                              }).toList(),
                            ),
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: Text('Buy'),
                              onPressed: () {
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
                )
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
                        Text('Scan result : $_scanBarcode\n',
                            style: TextStyle(fontSize: 20))
                      ]));
            })));
  }
}
