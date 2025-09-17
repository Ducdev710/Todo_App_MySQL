// lib/utils/app_constants.dart
class AppConstants {
  // ✅ APP INFO
  static const String appName = 'Todo App';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Ứng dụng quản lý công việc với .NET 8 API';

  // ✅ API INFO
  static const String apiVersion = '1.0.0';
  static const String apiDocumentation = '/swagger';

  // ✅ STORAGE KEYS
  static const String authTokenKey = 'auth_token';
  static const String userPrefsKey = 'user_preferences';
  static const String appThemeKey = 'app_theme';

  // ✅ DEFAULT VALUES
  static const int defaultTimeout = 30; // seconds
  static const int maxRetryAttempts = 3;
  static const int splashDuration = 2000; // milliseconds

  // ✅ VALIDATION LIMITS (matching backend)
  static const int maxTitleLength = 200;
  static const int maxDescriptionLength = 1000;
  static const int maxNameLength = 100;
  static const int maxEmailLength = 255;
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 100;

  // ✅ UI CONSTANTS
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double defaultElevation = 4.0;
}
