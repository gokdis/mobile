import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:math';
import 'package:gokdis/ble/stream_controller.dart';
import 'package:gokdis/settings.dart';
import 'package:provider/provider.dart';
import 'package:gokdis/user/shopping_list.dart';

class ble {
  String id;
  Coordinates coordinates;
  int rssi;
  double averageRSSI;
  double distance;

  ble(this.id, this.coordinates, this.rssi, this.distance, this.averageRSSI);

  double getDistance(double rssi) {
    double distance = pow(10, ((-65 - rssi) / (10 * 2))) as double;
    return distance;
  }
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
  // user x,y
  double x = 0.0;
  double y = 0.0;
  // user x,y
  double distance = 0.0;
  StreamSubscription<ScanResultEvent>? scanSubscription;

  static final Map<String, Coordinates> beaconCoordinates = {
    'C7:10:69:07:FB:51': Coordinates(0.0, 0.0),
    'F5:E5:8C:26:DB:7A': Coordinates(0.5, 0.0),
    'EB:6F:20:3B:89:E2': Coordinates(0.25, 0.43),
  };

  @override
  void initState() {
    super.initState();
    scanSubscription = scanResultStream.listen((ScanResultEvent event) {
      setState(() {
        x = event.x;
        y = event.y;
      });
    });
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
        withKeywords: ['10002', '10000', '26268'],
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
        print('Device ID: ${device.id}, Distance: ${device.distance}');
      }
    } catch (e) {
      print('Not enough devices : ${nearestDevices.length}');
    }

    return nearestDevices;
  }

  void getRSSI() {
    FlutterBluePlus.scanResults.listen((List<ScanResult> scanResults) {
      for (ScanResult result in scanResults) {
        String deviceId = result.device.remoteId.str;

        List<ble> nearestDevices;

        ble BLE = deviceRssiValues.keys.firstWhere(
          (key) => key.id == deviceId,
          orElse: () => ble(deviceId, Coordinates(0.0, 0.0), 0, -1, 0),
        );

        deviceRssiValues.putIfAbsent(BLE, () => []);

        deviceRssiValues[BLE]!.add(result.rssi);
        print('rssi: ${result.rssi} -- id : $deviceId');

        if (deviceRssiValues[BLE]!.length == 10) {
          List<int> _sortedValues = deviceRssiValues[BLE]!..sort();

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

          if (_sortedValues.length != 0) {
            double averageRSSI =
                _sortedValues.reduce((a, b) => a + b) / _sortedValues.length;
            BLE.averageRSSI = averageRSSI;
            print('Average RSSI: ${BLE.averageRSSI}');

            distance = BLE.getDistance(averageRSSI.toDouble());
            print("distance : $distance id : $deviceId");
            BLE.distance = distance;

            print('Avg distance : ${BLE.distance} --- id : ${BLE.id}');
            nearestDevices = getNearestThreeDevices();
            if (nearestDevices.length >= 3) {
              trilateration(
                  nearestDevices[0], nearestDevices[1], nearestDevices[2]);
            } else {
              print("Not enough devices for trilateration");
            }
            deviceRssiValues[BLE]!.clear();
            print("**************************************");
          } else {
            print("list is empty");
          }
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
        beaconCoordinates[beacon1.id] ?? Coordinates(0.0, 0.0);
    Coordinates coordinates2 =
        beaconCoordinates[beacon2.id] ?? Coordinates(0.0, 0.0);
    Coordinates coordinates3 =
        beaconCoordinates[beacon3.id] ?? Coordinates(0.0, 0.0);
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
    onScanResultReceived(x, y);
    print('x: $x y: $y');
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
              left: 0,
              top: 0,
              child: Icon(
                Icons.location_on,
                color: Colors.orange,
                size: 25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
