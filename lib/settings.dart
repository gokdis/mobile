class Settings {
  static const String scheme = "https";
  static const String baseURL = "gokdis.erke.biz.tr";
  static const String api = "api";
  static const String version = "v1";
  static const int port = 8443;

  //https://gokdis.erke.biz.tr:8443/api/v1/person

  static String get fullBaseUrl => '$scheme://$baseURL:$port/$api/$version';

  static String getUrl(String endpoint) {
    return '$fullBaseUrl/$endpoint';
  }
}
