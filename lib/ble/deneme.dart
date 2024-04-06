import 'dart:math';
import 'dart:async';

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

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:gokdis/ble/stream_controller.dart';
import 'package:gokdis/settings.dart';

class BLEScannerWidget1 extends StatefulWidget {
  @override
  Deneme createState() => Deneme();
}

void onScanResultReceived(double x, double y) {
  scanResultStreamController.add(ScanResultEvent(x, y));
}

class Deneme extends State<BLEScannerWidget1> {
  Map<RealBeacon, List<int>> deviceRssiValues = {};
  List<RealBeacon> nearestDevices = [];
  Point userLocation = Point(0, 0);

  @override
  void initState() {
    super.initState();
    scanSubscription = scanResultStream.listen((ScanResultEvent event) {
      setState(() {
        userLocation = Point(event.x, event.y);
      });
    });

    startScan();

    print(
        'Settings.globalBeaconCoordinates : ${Settings.globalBeaconCoordinates}');
  }

  StreamSubscription<ScanResultEvent>? scanSubscription;

  void startScan() async {
    try {
      await FlutterBluePlus.startScan(
        timeout: Duration(hours: 1),
        //withKeywords: ['26268', '10002', '10000'],
        continuousUpdates: true,
        continuousDivisor: 3,
        removeIfGone: Duration(minutes: 2),
      );
    } catch (e) {
      print("error : $e");
    }
    getRSSI();
  }

/*
  void startScanMock() {
    
    print("<----------- Start Mock Scan --------->");
    MockBeacon mockBeacon1 = MockBeacon(
      '26268',
      'c7:10:69:07:fb:51',
      Point(17, 41),
    );
    MockBeacon mockBeacon2 = MockBeacon(
      '10000',
      'f5:e5:8c:26:db:7a',
      Point(36, 41),
    );
    MockBeacon mockBeacon3 = MockBeacon(
      '100002',
      'eb:6f:20:3b:89:e2',
      Point(27, 49),
    );

    List<MockBeacon> mockBeacons = [
      mockBeacon1,
      mockBeacon2,
      mockBeacon3,
    ];

    Point userDevice = Point(0.5, 0.5);
    mockBeacon1.sendRssiAdvertisement(userDevice);
    mockBeacon2.sendRssiAdvertisement(userDevice);
    mockBeacon3.sendRssiAdvertisement(userDevice);
    Calculator calculator = LMA();
    print("Mock beacon 1: $mockBeacon1");
    print("Mock beacon 2: $mockBeacon2");
    print("Mock beacon 3: $mockBeacon3");
    userLocation = calculator.calculate(mockBeacons);
    onScanResultReceived(userLocation.x, userLocation.y);
    print("User location: $userLocation");
    print("<----------- End Mock Scan --------->");
   
  }
 */

  void getRSSI() {
    Random random = Random();
    FlutterBluePlus.scanResults.listen((List<ScanResult> scanResults) {
      for (ScanResult result in scanResults) {
        String deviceMAC = result.device.remoteId.toString();

        //Create random position for beacons
        //TODO: Set beacon positions from database and remove random
        double r1 = random.nextDouble() * 10;
        double r2 = random.nextDouble() * 10;
        RealBeacon beacon = RealBeacon(deviceMAC, 'Name', Point(r1, r2));
        updateDeviceRssiValues(beacon, result.rssi);
      }

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
        userLocation = tracker.finalPosition;
        print("User location: $userLocation");
      } else {
        print("Not enough devices for calculation");
      }

      /* Calculate user location without filter
      print("<------------Nearest Devices------------>");
      print(nearestDevices);

      if (nearestDevices.length == 3) {
        userLocation = calculator.calculate(nearestDevices);
        print("User position: $userLocation");
      } else {
        print("Not enough devices for calculation");
      }
      print("<--------------------------------------->");
      */
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
    return Scaffold(
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
            Positioned(
              //TODO: Show userLocation on the map
              left: calculateX(1, context),
              top: calculateY(1, context),
              child: Icon(
                Icons.location_on,
                color: Colors.amber,
                size: 3, 
              ),
            ),
            Positioned(
              left: calculateX(17, context),
              top: calculateY(41, context),
              child: Icon(
                Icons.location_on,
                color: Colors.red,
                size: 3,
              ),
            ),
            Positioned(
              left: calculateX(36, context),
              top: calculateY(41, context),
              child: Icon(
                Icons.location_on,
                color: Colors.red,
                size: 3, 
              ),
            ),
            Positioned(
              left: calculateX(27, context),
              top: calculateY(49, context),
              child: Icon(
                Icons.location_on,
                color: Colors.red,
                size: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to calculate X position based on grid position
  double calculateX(int gridX, BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return (gridX * 16.35 * screenWidth) / 1343;
  }

  // Function to calculate Y position based on grid position
  double calculateY(int gridY, BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return (gridY * 15.7 * screenHeight) / 2834;
  }
}
