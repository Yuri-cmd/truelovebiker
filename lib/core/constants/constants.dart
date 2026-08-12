class Constants {
  static const String productionUrl = 'https://hotelyuma.uk/api/';
  static const String localUrl = 'http://192.168.100.50/truelove-back/public/api/';
  static const bool useProduction = true;

  static String get baseUrl => useProduction ? productionUrl : localUrl;
}
