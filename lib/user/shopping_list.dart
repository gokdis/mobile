import 'package:flutter/material.dart';
import 'package:gokdis/user/special_offer.dart';
import 'package:gokdis/ble/barcode_reader.dart';
import 'package:provider/provider.dart';
import '../ble/asd.dart';
import 'package:gokdis/ble/global_variables.dart';

class ShoppingListWidget extends StatefulWidget {
  @override
  ShoppingListWidgetState createState() => ShoppingListWidgetState();
}

class ShoppingListWidgetState extends State<ShoppingListWidget> {
  List<dynamic> beaconData = [];
  late Set<String> uniqueAisles;
  late Map<String, String> sectionList = {};
  Map<String, List<Map<String, String>>> aisleProducts = {};
  bool dataLoaded = false;
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final global = Provider.of<Global>(context, listen: false);
      global.loadData();
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
                icon: Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                }),
            title: Text('Shopping List', style: TextStyle(color: Colors.white)),
            backgroundColor: Color(0xFF333366),
          ),
          drawer: Drawer(
            child: ListView.builder(
              itemCount: uniqueAislesList.length,
              itemBuilder: (BuildContext context, int index) {
                String aisleId = uniqueAislesList[index];
                return ExpansionTile(
                  leading: Icon(Icons.list, color: Color(0xFF333366)),
                  title: Text(aisleId,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  children: _buildProductList(aisleId),
                  backgroundColor: Colors.white,
                  collapsedBackgroundColor: Colors.grey[200],
                  iconColor: Color(0xFF333366),
                  textColor: Color(0xFF333366),
                  collapsedTextColor: Colors.black,
                  onExpansionChanged: (bool expanded) {
                    if (expanded &&
                        (aisleProducts[aisleId] == null ||
                            aisleProducts[aisleId]!.isEmpty)) {
                      String sectionId = global.sectionList.entries
                          .firstWhere(
                              (entry) =>
                                  entry.value.toLowerCase().trim() ==
                                  aisleId.toLowerCase().trim(),
                              orElse: () => MapEntry(
                                  "defaultSectionId", "defaultSectionId"))
                          .key;

                      List<Map<String, String>> products =
                          global.getProductsBySection(sectionId);
                      setState(() {
                        aisleProducts[aisleId] = products;
                      });
                    }
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

  List<Widget> _buildProductList(String aisleId) {
    List<Map<String, String>> products = aisleProducts[aisleId] ?? [];
    return products.map((product) {
      return ListTile(
        title: Text(product['name']!, style: TextStyle(color: Colors.black)),
        trailing: Text('Price: ${product['price']}',
            style: TextStyle(color: Color(0xFF333366))),
        onTap: () {}, 
      );
    }).toList();
  }

  // bottom navigation bar

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      color: Color(0xFF333366),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.map, color: Colors.white),
            onPressed: navigateToMap,
          ),
          IconButton(
            icon: Icon(Icons.campaign, color: Colors.white),
            onPressed: navigateToSpecialOffer,
          ),
          IconButton(
            icon: Icon(Icons.barcode_reader, color: Colors.white),
            onPressed: navigateToBarcodeReader,
          ),
        ],
      ),
    );
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
