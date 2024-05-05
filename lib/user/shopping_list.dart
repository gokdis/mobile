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
  Map<String, Map<String, dynamic>> cart = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

  void addToCart(String productName, String productPrice) {
    setState(() {
      if (cart.containsKey(productName)) {
        cart[productName]!['quantity'] += 1;
      } else {
        cart[productName] = {'quantity': 1, 'price': productPrice};
      }
    });
  }

  double getTotalPrice() {
    return cart.values.fold<double>(0.0,
        (double previousValue, Map<String, dynamic> element) {
      return previousValue +
          (element['quantity'] * double.parse(element['price']));
    });
  }

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
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(30.0),
              child: Container(
                color: Colors.white,
                height: 30.0,
                width: double.infinity,
                alignment: Alignment.center,
                child: Text(
                  'Total Price: \$${getTotalPrice().toStringAsFixed(2)}',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ),
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
          body: cart.isNotEmpty
              ? ListView.separated(
                  itemCount: cart.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey[300]),
                  itemBuilder: (context, index) {
                    String key = cart.keys.elementAt(index);
                    Map<String, dynamic> item = cart[key]!;
                    int quantity = item['quantity'];
                    String price = item['price'];

                    return ListTile(
                      leading:
                          Icon(Icons.shopping_cart, color: Colors.deepOrange),
                      title: Text(key,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Price: \$$price'),
                      trailing: Container(
                        width: 120,
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, color: Colors.red),
                              onPressed: () {
                                if (quantity > 1) {
                                  setState(() {
                                    cart[key]!['quantity']--;
                                  });
                                } else {
                                  setState(() {
                                    cart.remove(key);
                                  });
                                }
                              },
                            ),
                            Text('$quantity', style: TextStyle(fontSize: 18)),
                            IconButton(
                              icon: Icon(Icons.add, color: Colors.green),
                              onPressed: () {
                                setState(() {
                                  cart[key]!['quantity']++;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      onTap: () {},
                    );
                  },
                )
              : Center(
                  child: Text("Your cart is empty",
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.bold)),
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
              child:
                  Text(product['name']!, style: TextStyle(color: Colors.black)),
            ),
            IconButton(
              icon: Icon(Icons.add, color: Colors.black),
              onPressed: () {
                addToCart(product['name']!, product['price']!);
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
