import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:math';
import 'package:gokdis/ble/stream_controller.dart';
import 'package:gokdis/settings.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ble {
  //String id;
  String mac;
  Coordinates coordinates;
  int rssi;
  double averageRSSI;
  double distance;

  ble(this.mac, this.coordinates, this.rssi, this.distance, this.averageRSSI);

  double getDistance(double rssi) {
    double distance = pow(10, ((-65 - rssi) / (10 * 2))) as double;
    return distance;
  }

/*   double getDistance2(double rssi) {
    if (rssi == 0) {
      return -1.0; // if we cannot determine distance, return -1.
    }

    double ratio = rssi * 1.0 / 4;
    if (ratio < 1.0) {
      return pow(ratio, 10).toDouble();
    } else {
      double accuracy = (0.89976) * pow(ratio, 7.7095) + 0.111;
      return accuracy;
    }
  } */
}

class Coordinates {
  double x;
  double y;
  Coordinates(this.x, this.y);
  @override
  String toString() {
    return 'x: $x, y: $y';
  }
}

class BLEScannerWidget extends StatefulWidget {
  @override
  BLEScanner createState() => BLEScanner();
}

class BLEScanner extends State<BLEScannerWidget> {
  Map<ble, List<int>> deviceRssiValues = {};
  bool loggedinstatus = false;
  // user x,y
  double x = 0.0;
  double y = 0.0;

  // user x,y
  double distance = 0.0;
  StreamSubscription<ScanResultEvent>? scanSubscription;

  static Map<String, Coordinates> beaconCoordinates = {};

  @override
  void initState() {
    super.initState();
    scanSubscription = scanResultStream.listen((ScanResultEvent event) {
      setState(() {
        x = event.x;
        y = event.y;
      });
    });
    print(
        'Settings.globalBeaconCoordinates : ${Settings.globalBeaconCoordinates}');
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

  @override
  void dispose() {
    scanSubscription?.cancel();
    super.dispose();
  }

  void onScanResultReceived(double x, double y) {
    scanResultStreamController.add(ScanResultEvent(x, y));
  }

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

  void updateXY(double newX, double newY) {
    if (mounted) {
      setState(() {
        x = newX;
        y = newY;
      });
    } else {
      print("x and y has not been updated yet!");
    }
  }

  List<ble> getNearestThreeDevices() {
    List<ble> nearestDevices = [];

    try {
      final sortedDevices = deviceRssiValues.keys.toList()
        ..sort((a, b) => a.distance.compareTo(b.distance));

      nearestDevices =
          sortedDevices.where((device) => device.distance > 0).take(3).toList();

      print('Nearest 3 BLE devices:');
      for (final device in nearestDevices) {
        print('Device mac: ${device.mac}, Distance: ${device.distance}');
      }
    } catch (e) {
      print('Not enough devices : ${nearestDevices.length}');
    }

    return nearestDevices;
  }

  void getRSSI() {
    FlutterBluePlus.scanResults.listen((List<ScanResult> scanResults) {
      for (ScanResult result in scanResults) {
        String deviceMAC = result.device.remoteId.toString();

        List<ble> nearestDevices;

        ble BLE = deviceRssiValues.keys.firstWhere(
          (key) => key.mac == deviceMAC,
          orElse: () => ble(deviceMAC, Coordinates(0.0, 0.0), 0, -1, 0),
        );

        deviceRssiValues.putIfAbsent(BLE, () => []);
        deviceRssiValues[BLE]!.add(result.rssi);

        if (deviceRssiValues[BLE]!.length > 10) {
          deviceRssiValues[BLE]!.removeAt(0);
        }

        if (deviceRssiValues[BLE]!.length == 10) {
          List<int> _sortedValues = List<int>.from(deviceRssiValues[BLE]!);
          // ..sort();

          double mean =
              _sortedValues.reduce((a, b) => a + b) / _sortedValues.length;
          double sumOfSquares = _sortedValues.fold(0, (total, value) {
            double diff = value - mean;
            return total + diff * diff;
          });
          double stdDev = sqrt(sumOfSquares / _sortedValues.length);

          double lowerBound = mean - 2 * stdDev;
          double upperBound = mean + 2 * stdDev;

          _sortedValues.removeWhere(
              (value) => value < lowerBound || value >= upperBound);

          deviceRssiValues[BLE] = _sortedValues;

          if (_sortedValues.isNotEmpty) {
            double averageRSSI =
                _sortedValues.reduce((a, b) => a + b) / _sortedValues.length;
            BLE.averageRSSI = averageRSSI;
            print('Average RSSI: ${BLE.averageRSSI}');

            double distance = BLE.getDistance(averageRSSI.toDouble());
            print(
                'rssi: ${BLE.averageRSSI} -- mac : $deviceMAC -- distance $distance');

            BLE.distance = distance;

            print('Avg distance : ${BLE.distance} --- mac : ${BLE.mac}');
            nearestDevices = getNearestThreeDevices();
            beaconCoordinates = Settings.globalBeaconCoordinates;
            print('Array : ${deviceRssiValues[BLE]} -- mac : ${BLE.mac} ');
            if (nearestDevices.length >= 3) {
              trilateration(
                  nearestDevices[0], nearestDevices[1], nearestDevices[2]);
            } else {
              print("Not enough devices for trilateration");
            }
          } else {
            print("List is empty after filtering");
          }
          print("**************************************");
        }
      }
    });
    FlutterBluePlus.scanResults.handleError((error) {
      print('Error during scanning: $error');
    });
  }

  void trilateration(ble beacon1, ble beacon2, ble beacon3) {
    if (beacon1.distance <= 0 ||
        beacon2.distance <= 0 ||
        beacon3.distance <= 0) {
      print("Invalid distances from one or more beacons.");
      return;
    }

    Coordinates coordinates1 =
        beaconCoordinates[beacon1.mac] ?? Coordinates(0.0, 0.0);
    Coordinates coordinates2 =
        beaconCoordinates[beacon2.mac] ?? Coordinates(0.0, 0.0);
    Coordinates coordinates3 =
        beaconCoordinates[beacon3.mac] ?? Coordinates(0.0, 0.0);
    print('coordinat 1 : $coordinates1');
    print('coordinat 2 : $coordinates2');
    print('coordinat 3 : $coordinates3');

    double x1 = coordinates1.x;
    double y1 = coordinates1.y;
    double x2 = coordinates2.x;
    double y2 = coordinates2.y;
    double x3 = coordinates3.x;
    double y3 = coordinates3.y;
    double d1 = beacon1.distance;
    double d2 = beacon2.distance;
    double d3 = beacon3.distance;

    double A = 2 * (x2 - x1);
    double B = 2 * (y2 - y1);
    double C = (d1 * d1 - d2 * d2 - x1 * x1 + x2 * x2 - y1 * y1 + y2 * y2);
    double D = 2 * (x3 - x2);
    double E = 2 * (y3 - y2);
    double F = (d2 * d2 - d3 * d3 - x2 * x2 + x3 * x3 - y2 * y2 + y3 * y3);

    x = (C * E - F * B) / (E * A - B * D);
    y = (C * D - A * F) / (B * D - A * E);
    int x_int = x.toInt();
    int y_int = y.toInt();

    onScanResultReceived(x, y);

    print('x: $x y: $y');
    //sendCoordinatesToBackend(x_int, y_int);
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
    print("email $email");
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
              left:x * 5,
              top: y * 4.8,
              child: Icon(
                Icons.location_on,
                color: Colors.amber,
                size: 10,
              ),
            ),
            Positioned(
              left: 17 * 5,
              top: 41* 4.8,
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
            Text("x: $x , y: $y", )
          ],
        ),
      ),
    );
  }
}
