import 'package:flutter_dotenv/flutter_dotenv.dart';

class Settings {
  Settings._privateConstructor();

  static final Settings _instance = Settings._privateConstructor();

  static Settings get instance => _instance;
  late String _baseUrl;
  late String _url;
  void _initBaseUrl() {
    _baseUrl = dotenv.get('BASE_URL');
  }

  void _initIrl() {
    _url = dotenv.get('URL');
  }

  String get baseUrl => _baseUrl;

  String getUrl(String endpoint) {
    _initBaseUrl();

    return '$_baseUrl/$endpoint';
  }

  String getRecommandationUrl(String endpoint) {
    _initIrl();
    return '$_url$endpoint';
  }
}
