import 'dart:async';

final StreamController<ScanResultEvent> scanResultStreamController =
    StreamController<ScanResultEvent>.broadcast();

Stream<ScanResultEvent> get scanResultStream =>
    scanResultStreamController.stream;

class ScanResultEvent {
  final double x;
  final double y;

  ScanResultEvent(this.x, this.y);
}
