class AppConstants {
  static const String appName = 'Sổ Tay Y Tế';
  static const String appVersion = '1.0.0';

  // API Endpoints
  static const String baseUrl = 'https://api.sotayyte.vn/v1';
  static const String syncEndpoint = '/sync';
  static const String authEndpoint = '/auth';

  // Storage Keys
  static const String userTokenKey = 'USER_TOKEN';
  static const String isProUserKey = 'IS_PRO_USER';
  static const String lastSyncTimestampKey = 'LAST_SYNC_TIMESTAMP';
}
