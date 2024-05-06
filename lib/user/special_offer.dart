import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gokdis/ble/global_variables.dart';

class SpecialOffer extends StatefulWidget {
  @override
  _SpecialOfferState createState() => _SpecialOfferState();
}

class _SpecialOfferState extends State<SpecialOffer> {
  Map<String, dynamic> _recommendedItems = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Special Offers',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.deepOrange,
      ),
      body: Consumer<Global>(
        builder: (context, global, child) {
          _recommendedItems = Provider.of<Global>(context, listen: false).recommendedItems;

          List<String> items = List<String>.from(
              _recommendedItems['recommendations']
                      ?.map((item) => item.toString()) ??
                  []);

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2, 
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: ListTile(
                    title: Text(
                      items[index],
                      style: TextStyle(fontSize: 16),
                    ),
                    leading: Icon(Icons.check_circle_outline, color: Colors.deepOrange),
                 
                    onTap: () {
             
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}