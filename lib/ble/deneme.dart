import 'package:epitaph_ips/epitaph_ips/buildings/point.dart';
import 'package:epitaph_ips/epitaph_ips/positioning_system/beacon.dart';
import 'package:epitaph_ips/epitaph_ips/positioning_system/mock_beacon.dart';
import 'package:epitaph_ips/epitaph_ips/positioning_system/real_beacon.dart';
import 'package:epitaph_ips/epitaph_ips/tracking/lma.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gokdis/ble/stream_controller.dart';
import 'package:gokdis/settings.dart';

import 'package:epitaph_ips/epitaph_ips/tracking/calculator.dart';

class BLEScannerWidget1 extends StatefulWidget {
  @override
  Deneme createState() => Deneme();
}

void onScanResultReceived(double x, double y) {
  scanResultStreamController.add(ScanResultEvent(x, y));
}

class Deneme extends State<BLEScannerWidget1> {
  Point userLocation = Point(1, 0);
  @override
  void initState() {
    super.initState();
    scanSubscription = scanResultStream.listen((ScanResultEvent event) {
      setState(() {
        userLocation = Point(event.x, event.y);
        
      });
    });
    startscan();
    print(
        'Settings.globalBeaconCoordinates : ${Settings.globalBeaconCoordinates}');
  }

  StreamSubscription<ScanResultEvent>? scanSubscription;

  void startscan() {
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
              alignment: Alignment.topLeft,
              "assets/images/supermarket.png",
              height: double.infinity,
              width: double.infinity,
            ),
            Positioned(
              left: userLocation.x * 5,
              top: userLocation.y * 4.8,
              child: Icon(
                Icons.location_on,
                color: Colors.amber,
                size: 10,
              ),
            ),
            Positioned(
              left: 17 * 5,
              top: 41 * 4.8,
              child: Icon(
                Icons.location_on,
                color: Colors.red,
                size: 2,
              ),
            ),
            Positioned(
              left: 36 * 5,
              top: 41 * 4.8,
              child: Icon(
                Icons.location_on,
                color: Colors.red,
                size: 2,
              ),
            ),
            Positioned(
              left: 27 * 5,
              top: 49 * 4.8,
              child: Icon(
                Icons.location_on,
                color: Colors.red,
                size: 2,
              ),
            ),
            // Text("x: $x , y: $y", )
          ],
        ),
      ),
    );
  }
}
