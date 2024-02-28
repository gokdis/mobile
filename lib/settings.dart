import 'package:flutter_dotenv/flutter_dotenv.dart';

class Settings {
  late String baseUrl;

  String getUrl(String endpoint) {
    baseUrl = dotenv.get('BASE_URL');

    return '$baseUrl/$endpoint';
  }
}
