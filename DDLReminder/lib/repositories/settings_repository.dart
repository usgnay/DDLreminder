import '../models/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> readSettings();
  Future<void> writeSettings(AppSettings settings);
  Future<String> cacheBackgroundImage(String sourcePath);
  Future<void> cleanupBackgroundImageCache({
    String? activePath,
    int maxFiles = 8,
  });
}
