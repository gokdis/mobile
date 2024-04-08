import 'package:epitaph_ips/epitaph_ips/buildings/point.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class Settings {
  Settings._privateConstructor();

  static final Settings _instance = Settings._privateConstructor();

  static Settings get instance => _instance;
  static Map<String, Point> globalBeaconCoordinates = {};
  late String _baseUrl;

  void _initBaseUrl() {
    _baseUrl = dotenv.get('BASE_URL');
  }

  String get baseUrl => _baseUrl;

  String getUrl(String endpoint) {
    _initBaseUrl();
    
    return '$_baseUrl/$endpoint';
  }
}
