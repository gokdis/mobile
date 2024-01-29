import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:math';
//import 'package:simple_kalman/simple_kalman.dart';

class ble {
  String id;
  double x;
  double y;
  int rssi;
  double averageRSSI;
  double distance;

  ble(this.id, this.x, this.y, this.rssi, this.distance, this.averageRSSI);

  double getDistance(double rssi) {
    double distance = pow(10, ((-65 - rssi) / (10 * 2))) as double;
    return distance;
  }
}

class BLEScanner {
  Map<ble, List<int>> deviceRssiValues = {};
  late double distance;

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

  List<ble> getNearestThreeDevices() {
    final sortedDevices = deviceRssiValues.keys.toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));

    final nearestDevices =
        sortedDevices.where((device) => device.distance > 0).take(3).toList();

    print('Nearest 3 BLE devices:');
    for (final device in nearestDevices) {
      print('Device ID: ${device.id}, Distance: ${device.distance}');
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
          orElse: () => ble(deviceId, 0, 0, 0, -1, 0),
        );

        deviceRssiValues.putIfAbsent(
            BLE,
            () =>
                []); // initializes an empty list if device does not have rssi value

        //BLE.rssi = result.rssi;
        deviceRssiValues[BLE]!.add(result.rssi);
        //  print('rssi: ${result.rssi}');
        //  print('id : $deviceId');
        //  print('List : ${deviceRssiValues[BLE]}');
        if (deviceRssiValues[BLE]!.length == 10) {
          List<int> _sortedValues = deviceRssiValues[BLE]!..sort();
          //   print(' sorted values : $_sortedValues');
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
            //  print('Average RSSI: ${BLE.averageRSSI}');

            distance = BLE.getDistance(averageRSSI.toDouble());
            BLE.distance = distance;

            print('Avg distance : ${BLE.distance} --- id : ${BLE.id}');
            nearestDevices = getNearestThreeDevices();
            trilateration(
                nearestDevices[0], nearestDevices[1], nearestDevices[2]);
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

  void trilateration(ble beacon1, ble beacon2, ble beacon3) {}

/*     void kalman() {
      List<int> rssi = [];

    for (List<int> valuesList in deviceRssiValues.values) {
      rssi.addAll(valuesList);
    }
    final kalman = SimpleKalman(errorMeasure: 256, errorEstimate: 150, q: 0.9);

    for (final value in rssi) {
      print('Origin: $value Filtered: ${kalman.filtered(value.toDouble())}');

    }
  } */
}
