class ApiConfig {
  // Use the emulator host for local Android emulators; physical phones need an explicit URL.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  static const String storageUrl = String.fromEnvironment(
    'STORAGE_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/storage',
  );

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  static const String facebookAppId = String.fromEnvironment('FACEBOOK_APP_ID');

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  static const String resources = '$baseUrl/resources';
  static const String uploadResource = '$baseUrl/resources/upload';
  static const String authLogin = '$baseUrl/auth/login';

  static bool get hasProductionApiUrl => _isProductionUrl(baseUrl);
  static bool get hasProductionStorageUrl => _isProductionUrl(storageUrl);

  static bool _isProductionUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        uri.host != 'localhost' &&
        uri.host != '127.0.0.1' &&
        uri.host != '10.0.2.2';
  }
}
