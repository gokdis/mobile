import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:math';
//import 'package:simple_kalman/simple_kalman.dart';

class BLEScanner {
  Map<String, List<int>> deviceRssiValues = {};

  void startScan() async {
    try {
      await FlutterBluePlus.startScan(
        timeout: Duration(hours: 1),
        withKeywords: ['10000','10001'],
        continuousUpdates: true,
      );
    } catch (e) {
      print("error");
    }
    //testOutliers();
    getRSSI();
  }

  void testOutliers() {
    List<int> sortedValues = [-87, -42, -19, -63, -35, -56, -92, -10, -74, -28];
    sortedValues.sort();
    print(sortedValues);

    int n = sortedValues.length;
    double index1 = ((n + 1) / 4) - 1;
    double index2 = ((3 * (n + 1)) / 4) - 1;
    print(index1.floor()); // .floor() casts 2.5 to 2
    print(index2.floor());

    double q1;
    if (index1 % 2 == 0) {
      q1 = sortedValues[index1.toInt()].toDouble();
    } else {
      q1 = (((sortedValues[index1.floor()]).toDouble() +
                  (sortedValues[(index1 + 1).floor()]).toDouble()) /
              2)
          .toDouble();
    }
    print(q1);

    double q3;
    if (index2 % 2 == 0) {
      q3 = sortedValues[index2.toInt()].toDouble();
    } else {
      q3 = (((sortedValues[index2.floor()]).toDouble() +
                  (sortedValues[(index2 + 1).floor()]).toDouble()) /
              2)
          .toDouble();
    }

    print(q3);
    double iqr = q3 - q1;
    print(iqr);
  }

  /*
   q1 = (n+1)/4
   q3 = 3(n+1)/4
   iqr = q3-q1

   outliers:
   x > q3 && x < q1

*/
  void getRSSI() {
    FlutterBluePlus.scanResults.listen((List<ScanResult> scanResults) {
      for (ScanResult result in scanResults) {
        String deviceId = result.device.remoteId.str;

        deviceRssiValues.putIfAbsent(
            deviceId,
            () =>
                []); // initializes an empty list if device does not have rssi value

        deviceRssiValues[deviceId]!.add(result.rssi);
        print('rssi: ${result.rssi}');

        double distance = getDistance(result.rssi.toDouble());
        print('Distance: $distance m');

        if (deviceRssiValues[deviceId]!.length == 10) {
          List<int> _sortedValues = deviceRssiValues[deviceId]!..sort();

          int _n = _sortedValues.length;
          double _index1 = ((_n + 1) / 4) - 1;

          double _index2 = ((3 * (_n + 1)) / 4) - 1;

          double _q1;
          if (_index1 % 2 == 0) {
            _q1 = _sortedValues[_index1.toInt()].toDouble();
          } else {
            _q1 = (((_sortedValues[_index1.floor()]).toDouble() +
                        (_sortedValues[(_index1 + 1).floor()]).toDouble()) /
                    2)
                .toDouble();
          }
          double _q3;
          if (_index2 % 2 == 0) {
            _q3 = _sortedValues[_index2.toInt()].toDouble();
          } else {
            _q3 = (((_sortedValues[_index2.floor()]).toDouble() +
                        (_sortedValues[(_index2 + 1).floor()]).toDouble()) /
                    2)
                .toDouble();
          }
          double _iqr = _q3 - _q1;

          deviceRssiValues[deviceId]!.removeWhere(
              (value) => value < _q1 - 1.5 * _iqr || value > _q3 + 1.5 * _iqr);

          int _sum = deviceRssiValues[deviceId]!.reduce((a, b) => a + b);
          int avg = _sum ~/ deviceRssiValues[deviceId]!.length;

          double _sumDistance = deviceRssiValues[deviceId]!
            .map((rssi) => getDistance(rssi.toDouble()))
            .reduce((a, b) => a + b);
          double avgDistance = _sumDistance / deviceRssiValues[deviceId]!.length;
          print('Avg Distance for $deviceId: $avgDistance m');

          print('Avg rssi for $deviceId: $avg');

          deviceRssiValues[deviceId]!.clear();
        }
      }
    });

    FlutterBluePlus.scanResults.handleError((error) {
      print('Error during scanning: $error');
    });
  }

  double getDistance(double rssi) {
    double distance = pow(10, ((-65 - rssi) / (10 * 2))) as double;
    return distance;
  }


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
