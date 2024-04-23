import 'dart:convert';
import 'dart:math';
import 'dart:async';

import 'package:http/http.dart' as http;

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
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:gokdis/ble/stream_controller.dart';
import 'package:gokdis/settings.dart';
import 'package:gokdis/user/login.dart';

class Aisle {
  final String name;
  Point coordinates;

  Aisle(this.name, this.coordinates);
}

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
  static Map<String, Point> beaconCoordinates = {};
  bool loggedinstatus = false;

  // TODO: Populate aisle list from database
  List<Aisle> aisleCoordinates = [
    Aisle('Deli', Point(280, 640)),
    Aisle('Snack', Point(36, 41)),
    Aisle('Bakery', Point(27, 49)),
  ];

  Map<String, bool> aisleMarkersVisibility = {};

  double x = 0.0;
  double y = 0.0;
  @override
  void initState() {
    super.initState();

    // Make aisle markers invisible
    aisleCoordinates.forEach((aisle) {
      aisleMarkersVisibility[aisle.name] = false;
    });

    scanSubscription = scanResultStream.listen((ScanResultEvent event) {
      setState(() {
        userLocation = Point(event.x, event.y);
      });
    });
    print(beaconCoordinates);

    startScan();
    //startAisleMovement();
    print(
        'Settings.globalBeaconCoordinates : ${Settings.globalBeaconCoordinates}');
  }

  void startAisleMovement() {
  Timer.periodic(Duration(milliseconds: 200), (timer) {
    setState(() {
      aisleCoordinates[0].coordinates = Point(aisleCoordinates[0].coordinates.x, aisleCoordinates[0].coordinates.y + 1);

      print(aisleCoordinates[0].coordinates);
    });
  });
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
    FlutterBluePlus.scanResults.listen((List<ScanResult> scanResults) {
      for (ScanResult result in scanResults) {
        String deviceMAC = result.device.remoteId.toString();

        beaconCoordinates = Settings.globalBeaconCoordinates;

        Point? point = beaconCoordinates[deviceMAC];

        if (point != null) {
          RealBeacon beacon =
              RealBeacon(deviceMAC, 'name', Point(point.x, point.y));
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

      //Mock customer
      startMockCustomer();

      //Calculate user location
      if (nearestDevices.length == 3) {
        tracker.initiateTrackingCycle(nearestDevices);
        userLocation = tracker.calculatedPosition; //finalPosition
        onScanResultReceived(userLocation.x, userLocation.y);
        sendCoordinatesToBackend(
            userLocation.x.toInt(), userLocation.y.toInt());
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

  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<void> sendCoordinatesToBackend(int x, int y) async {
    loggedinstatus = await isLoggedIn();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String uuid = generateRandomUuid();

    String url = Settings.instance.getUrl('position');
    String? email = prefs.getString('email');
    String? password = prefs.getString('password');
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$email:$password'));
    String currentTime = DateTime.now().toIso8601String();

    Map<String, dynamic> payload = {
      'id': uuid,
      'personEmail': email,
      'x': x,
      'y': y,
      'time': currentTime,
    };

    final Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      'Authorization': basicAuth,
    };

    try {
      if (loggedinstatus) {
        final response = await http.post(
          Uri.parse(url),
          headers: requestHeaders,
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200) {
          print('Coordinates sent successfully : $x $y');
        } else {
          print(
              'Failed to send coordinates. Status code: ${response.statusCode}');
        }
      } else {
        print("not logged in");
      }
    } catch (e) {
      print('Error sending coordinates: $e');
    }
  }

  void startMockCustomer() {
    int phase = 0; // 0 - right, 1 - down, 2 - left, 3 - up
    int timeCounter = 0;
    userLocation = Point(14, 43);

    Timer.periodic(Duration(milliseconds: 1000), (timer) {
      setState(() {
        switch (phase) {
          case 0: // Walking right
            if (timeCounter < 46) {
              userLocation = Point(userLocation.x + 1, userLocation.y);
              timeCounter++;
            } else {
              phase = 1;
              timeCounter = 0;
            }
            break;
          case 1: // Walking down
            if (timeCounter < 8) {
              userLocation = Point(userLocation.x, userLocation.y + 1);
              timeCounter++;
            } else {
              phase = 2;
              timeCounter = 0;
            }
            break;
          case 2: // Walking left
            if (timeCounter < 46) {
              userLocation = Point(userLocation.x - 1, userLocation.y);
              timeCounter++;
            } else {
              phase = 3;
              timeCounter = 0;
            }
            break;
          case 3: // Walking up
            if (timeCounter < 8) {
              userLocation = Point(userLocation.x, userLocation.y - 1);
              timeCounter++;
            } else {
              phase = 0;
              timeCounter = 0;
            }
            break;
        }
      });
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
            // Display aisle markers
            for (var aisle in aisleCoordinates)
              if (aisleMarkersVisibility[aisle.name] == true)
                Positioned(
                  left: calculateX(aisle.coordinates.x, context),
                  top: calculateY(aisle.coordinates.y, context),
                  child: Container(
                    width: 1, 
                    height: 1, 
                    color:
                        Colors.blue.withOpacity(1), 
                  ),
                ),
            // Display user location marker
            Positioned(
              left: calculateX(userLocation.x, context),
              top: calculateY(userLocation.y, context),
              child: Icon(
                Icons.location_on,
                color: Colors.amber,
                size: 10,
              ),
            ),
          ],
        ),
      ),
      // Add aisle buttons
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          for (var aisle in aisleCoordinates)
            FloatingActionButton(
              onPressed: () {
                // Toggle the visibility of the aisle marker
                setState(() {
                  aisleMarkersVisibility[aisle.name] =
                      !aisleMarkersVisibility[aisle.name]!;
                });
              },
              child: Text(aisle.name),
            ),
        ],
      ),
    );
  }

  // Function to calculate X position based on grid position
  double calculateX(double gridX, BuildContext context) {
    //double screenWidth = MediaQuery.of(context).size.width;
    //return (gridX * 16.35 * screenWidth) / 1343;
    return gridX / 3.42;
  }

  // Function to calculate Y position based on grid position
  double calculateY(double gridY, BuildContext context) {
    //double screenHeight = MediaQuery.of(context).size.height;
    //return (gridY * 15.7 * screenHeight) / 2834;
    return gridY / 3.42;
  }
}
