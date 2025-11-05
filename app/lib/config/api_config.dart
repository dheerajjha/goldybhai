/// API Configuration
///
/// This is the single source of truth for all API endpoints.
/// Change the base URL here to switch between environments.
class ApiConfig {
  // Base URL for the backend API
  // For production, use: 'https://api-goldy.sexy.dog'
  // For local development, use: 'http://192.168.1.3:3000' or 'http://localhost:3000'
  // static const String baseUrl = 'http://192.168.1.3:3000';
  static const String baseUrl = 'https://api-goldy.sexy.dog';

  // API endpoints
  static const String apiPath = '/api';
  static const String fullApiUrl = '$baseUrl$apiPath';

  // Environment helpers
  static bool get isProduction => baseUrl.contains('api-goldy.sexy.dog');
  static bool get isDevelopment => !isProduction;
}
