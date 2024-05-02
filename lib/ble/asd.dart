import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:gokdis/ble/global_variables.dart';

import 'package:epitaph_ips/epitaph_ips/buildings/point.dart';
import 'package:epitaph_ips/epitaph_ips/positioning_system/mock_beacon.dart';
import 'package:epitaph_ips/epitaph_ips/positioning_system/real_beacon.dart';
import 'package:epitaph_ips/epitaph_ips/tracking/filter.dart';
import 'package:epitaph_ips/epitaph_ips/tracking/lma.dart';
import 'package:epitaph_ips/epitaph_ips/tracking/merwe_function.dart';
import 'package:epitaph_ips/epitaph_ips/tracking/sigma_point_function.dart';
import 'package:epitaph_ips/epitaph_ips/tracking/simple_ukf.dart';
import 'package:epitaph_ips/epitaph_ips/tracking/tracker.dart';
import 'package:epitaph_ips/epitaph_ips/tracking/calculator.dart';
import 'package:ml_linalg/matrix.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:gokdis/ble/stream_controller.dart';
import 'package:gokdis/settings.dart';

class Aisle {
  final String name;
  Point coordinates;
  bool visible;
  String color;

  Aisle(this.name, this.coordinates, {this.visible = false, this.color = ""});

  @override
  String toString() {
    return 'Aisle(name: $name, coordinates: $coordinates, visible: $visible)';
  }
}

class BLEScannerWidget extends StatefulWidget {
  @override
  Deneme createState() => Deneme();
}

void onScanResultReceived(double x, double y) {
  scanResultStreamController.add(ScanResultEvent(x, y));
}
/**
 * coordinates for new map
 *   'EB:6F:20:3B:89:E2': Point(435, 767),
    'C7:10:69:07:FB:51': Point(280, 640),
    'F5:E5:8C:26:DB:7A': Point(590, 640),
 * 
 *  Settings.globalBeaconCoordinates : {EB:6F:20:3B:89:E2: Point(x: 435.0, y: 767.0, z: 0.0), 
 * C7:10:69:07:FB:51: Point(x: 280.0, y: 640.0, z: 0.0), F5:E5:8C:26:DB:7A: Point(x: 590.0, y: 640.0, z: 0.0)}

 */

class Deneme extends State<BLEScannerWidget> {
  Map<RealBeacon, List<int>> deviceRssiValues = {};
  List<RealBeacon> nearestDevices = [];
  Point userLocation = Point(0, 0);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // variables for aisle
  late Future<void> _aislesFuture;
  List<Aisle> aisleCoordinates = [];
  List<dynamic> aisleData = [];
  Set<String> uniqueAisles = Set();
  bool dataLoaded = false;

  // coordinates for old map
  static Map<String, Point> beaconCoordinates = {};

  double x = 0.0;
  double y = 0.0;
  @override
  void initState() {
    super.initState();
    scanSubscription = scanResultStream.listen((ScanResultEvent event) {
      setState(() {
        userLocation = Point(event.x, event.y);
      });
    });
    print(beaconCoordinates);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final global = Provider.of<Global>(context, listen: false);
      global.getAislesFromTXT();
    });
    uniqueAisles = Provider.of<Global>(context, listen: false).uniqueAisles;

    print(
        'Settings.globalBeaconCoordinates : ${Settings.globalBeaconCoordinates}');
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    super.dispose();
  }

  StreamSubscription<ScanResultEvent>? scanSubscription;

  void startScan() async {
    try {
      await FlutterBluePlus.startScan(
        timeout: Duration(hours: 1),
        withKeywords: ['26268', '10002', '10000'],
        continuousUpdates: true,
        continuousDivisor: 3,
        removeIfGone: Duration(minutes: 2),
      );
    } catch (e) {
      print("error : $e");
    }
    getRSSI();
  }

  void getRSSI() {
    FlutterBluePlus.scanResults.listen((List<ScanResult> scanResults) {
      for (ScanResult result in scanResults) {
        String deviceMAC = result.device.remoteId.toString();

        beaconCoordinates = Settings.globalBeaconCoordinates;

        Point? point = beaconCoordinates[deviceMAC];

        if (point != null) {
          RealBeacon beacon =
              RealBeacon(deviceMAC, 'name', Point(point.x / 14, point.y / 14));
          updateDeviceRssiValues(beacon, result.rssi);
        }
      }

      print(deviceRssiValues);

      //Calculate user location with filter
      //Initialize calculator
      Calculator calculator = LMA();

      //Very basic models for unscented Kalman filter
      Matrix fxUserLocation(Matrix x, double dt, List? args) {
        List<double> list = [
          x[1][0] * dt + x[0][0],
          x[1][0],
          x[3][0] * dt + x[2][0],
          x[3][0]
        ];
        return Matrix.fromFlattenedList(list, 4, 1);
      }

      Matrix hxUserLocation(Matrix x, List? args) {
        return Matrix.row([x[0][0], x[0][2]]);
      }

      //Sigma point function for unscented Kalman filter
      SigmaPointFunction sigmaPoints = MerweFunction(4, 0.1, 2.0, 1.0);

      //Initialize filter
      Filter filter = SimpleUKF(4, 2, 0.3, hxUserLocation, fxUserLocation,
          sigmaPoints, sigmaPoints.numberOfSigmaPoints());

      //Initialize tracker
      Tracker tracker = Tracker(calculator, filter);

      //Calculate user location
      if (nearestDevices.length == 3) {
        tracker.initiateTrackingCycle(nearestDevices);
        userLocation = tracker.calculatedPosition; //finalPosition
        onScanResultReceived(userLocation.x / 14, userLocation.y / 14);

        print("User location: $userLocation");
      } else {
        print("Not enough devices for calculation");
      }
    });

    FlutterBluePlus.scanResults.handleError((error) {
      print('Error during scanning: $error');
    });
  }

  // Store RealBeacons and RSSI values
  void updateDeviceRssiValues(RealBeacon beacon, int rssi) {
    // Check if the beacon's ID already exists in the map
    bool beaconExists = deviceRssiValues.keys.any((key) => key.id == beacon.id);

    if (beaconExists) {
      // If beacon exists, add rssi value to the list in the key for that beacon
      List<int> rssiList = deviceRssiValues[
          deviceRssiValues.keys.firstWhere((key) => key.id == beacon.id)]!;
      rssiList.add(rssi);

      // If the number of elements exceeds 10, remove the first element
      if (rssiList.length > 10) {
        rssiList.removeAt(0);
      }
    } else {
      // If beacon doesn't exist, add it to the map and initialize a new list with rssi value
      deviceRssiValues[beacon] = [rssi];
    }

    getNearestDevices();
  }

  // Get the average of RSSIs for each beacon and get the nearest 3 devices
  void getNearestDevices() {
    Map<RealBeacon, double> averageRssiMap = {};

    deviceRssiValues.forEach((beacon, rssiList) {
      double averageRssi = rssiList.isNotEmpty
          ? rssiList.reduce((a, b) => a + b) / rssiList.length
          : double.negativeInfinity;
      averageRssiMap[beacon] = averageRssi;
    });

    // Sort beacons based on average RSSI
    List<RealBeacon> sortedBeacons = averageRssiMap.keys.toList()
      ..sort((a, b) => averageRssiMap[b]!.compareTo(averageRssiMap[a]!));

    // Get the three beacons with the highest average RSSI
    nearestDevices = sortedBeacons.take(3).toList();

    // Update RSSI for nearest devices
    nearestDevices.forEach((beacon) {
      double averageRssi = averageRssiMap[beacon]!;
      int averageRssiInt = averageRssi.toInt();
      beacon.rssiUpdate(averageRssiInt); // Call rssiUpdate
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
            title: Text('Shopping List'),
            backgroundColor: Color(0xFFFFA500),
          ),
          drawer: Drawer(
            child: ListView.builder(
              itemCount: uniqueAislesList.length,
              itemBuilder: (BuildContext context, int index) {
                var aisleId = uniqueAislesList[index];
                return ListTile(
                  title: Text(aisleId),
                  onTap: () {
                    _scaffoldKey.currentState?.closeDrawer();

                    setState(() {
                      for (var aisle in global.aisleCoordinates) {
                        if (aisle.name == aisleId) {
                          aisle.visible = !aisle.visible;
                        }
                      }
                    });
                  },
                );
              },
            ),
          ),
          body: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: EdgeInsets.all(80),
            minScale: 0.5,
            maxScale: 4,
            child: Stack(
              children: <Widget>[
                Image.asset(
                  "assets/images/supermarket.png",
                  fit: BoxFit.contain,
                ),
                for (var aisle in global.aisleCoordinates)
                  if (aisle.visible)
                    Positioned(
                  
                      left: calculateXAisle(aisle.coordinates.x, context),
                      top: calculateYAisle(aisle.coordinates.y, context),
                      child: Container(
                        width: calculateXAisle(16, context),
                        height: calculateXAisle(16, context),
                        color: Colors.blue.withOpacity(0.5),
                      ),
                    ),
                Positioned(
                  left: calculateXAisle(435, context),
                  top: calculateYAisle(630, context),
                  child: Icon(
                    Icons.location_on,
                    color: Colors.amber,
                    size: 30,
                  ),
                ),
                Positioned(
                  left: calculateXAisle(280, context),
                  top: calculateYAisle(640, context),
                  child: Icon(
                    Icons.bluetooth,
                    color: Colors.blue,
                    size: 30,
                  ),
                ),
                Positioned(
                  left: calculateXAisle(590, context),
                  top: calculateYAisle(640, context),
                  child: Icon(
                    Icons.bluetooth,
                    color: Colors.blue,
                    size: 30,
                  ),
                ),
                Positioned(
                  left: calculateXAisle(435, context),
                  top: calculateYAisle(767, context),
                  child: Icon(
                    Icons.bluetooth,
                    color: Colors.blue,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// old map coordinates
  // Function to calculate X position based on grid position
  double calculateX(double gridX, BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return (gridX * 16.35 * screenWidth) / 1343;
  }

  // Function to calculate Y position based on grid position
  double calculateY(double gridY, BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return (gridY * 15.7 * screenHeight) / 2834;
  }
//-----------------------------------------------------------------------------

// new map coordinates
  // Function to calculate X position based on grid position
  double calculateXAisle(double gridX, BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double ratio = 1343 / screenWidth;

    return gridX / ratio;
  }

  // Function to calculate Y position based on grid position
  double calculateYAisle(double gridY, BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double ratio = 2834 / screenHeight;

    return gridY / ratio;
  }
}