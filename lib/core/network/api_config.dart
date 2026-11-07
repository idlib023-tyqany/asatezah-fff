class ApiConfig {
  // تم تحديث القيمة الافتراضية لتشير إلى سيرفر Render الإنتاجي مباشرة
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://asatezah-bbb.onrender.com/api',
  );

  static const String storageUrl = String.fromEnvironment(
    'STORAGE_BASE_URL',
    defaultValue: 'https://asatezah-bbb.onrender.com/storage',
  );

  // مفتاح جوجل جيميني (استبدل النص بمفتاحك الحقيقي من Google AI Studio)
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

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
