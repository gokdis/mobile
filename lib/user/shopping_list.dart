import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                icon: Icon(Icons.menu),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                }),
            title: Text('Shopping List', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.deepOrange,
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
        );
      },
    );
  }

List<Widget> _buildProductList(String aisleId) {
  List<Map<String, String>> products = aisleProducts[aisleId] ?? [];
  return products.map((product) {
    return ListTile(
      title: Row(
        children: [
          Expanded( 
            child: Text(product['name']!, style: TextStyle(color: Colors.black)),
          ),
          IconButton(
            icon: Icon(Icons.add, color: Colors.black), 
            onPressed: () {
              print("Add button pressed for ${product['name']}");
            },
          ),
        ],
      ),
      trailing: Text('Price: ${product['price']}',
          style: TextStyle(color: Color(0xFF333366))),
      onTap: () {
        print("ListTile tapped for ${product['name']}");
      },
    );
  }).toList();
}

}
