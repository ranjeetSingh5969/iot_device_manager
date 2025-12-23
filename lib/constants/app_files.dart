class AppFiles {
  AppFiles._();

  // Database
  static const String databaseName = 'iot_device_manager.db';
  static const int databaseVersion = 1;

  // Shared Preferences Keys
  static const String authTokenKey = 'auth_token';
  static const String clientIdKey = 'client_id';
  static const String emailKey = 'email';

  // API Endpoints
  static const String apiBaseUrl = 'https://api.example.com';
  static const String apiLoginEndpoint = '/auth/login';
  static const String apiDevicesEndpoint = '/devices';
  static const String apiSyncEndpoint = '/sync';

  // File Paths
  static const String assetsImages = 'assets/images/';
  static const String assetsIcons = 'assets/icons/';
}

