import 'dart:convert';
import 'package:flutter/services.dart';

import 'package:epitaph_ips/epitaph_ips/buildings/point.dart';
import 'package:flutter/material.dart';
import 'asd.dart';

class Global extends ChangeNotifier {
  List<Aisle> _aisleCoordinates = [];
  Set<String> _uniqueAisles = Set();

  bool dataLoaded = false;
  Set<String> get uniqueAisles => _uniqueAisles;
  List<Aisle> get aisleCoordinates => _aisleCoordinates;

  Future<void> getAislesFromTXT() async {
    if (dataLoaded == false) {
      print("DUR");
      try {
        String textasset = "assets/cells.json";
        String text = await rootBundle.loadString(textasset);

        List<dynamic> jsonResponse = jsonDecode(text);

        updateAisle(jsonResponse);
        
      } catch (error) {
        print("Error occurred while reading data from file: $error");
      }
    }
  }

void updateAisle(List<dynamic> aisleData) {
    print("Updating aisles with new data"); // Debug statement
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
    dataLoaded = true;
    print("Aisle data loaded: $_aisleCoordinates"); // Debug statement
}

}
