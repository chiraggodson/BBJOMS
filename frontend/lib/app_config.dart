class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'BBJOMS_API_BASE_URL',
    defaultValue: 'http://192.168.1.69:4000/api',
  );
}