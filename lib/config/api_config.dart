class ApiConfig {
  // Override these values per target with --dart-define for a physical device
  // or a deployed environment. The emulator defaults preserve local Android use.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );
  static const String storageUrl = String.fromEnvironment(
    'STORAGE_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/storage',
  );
}
