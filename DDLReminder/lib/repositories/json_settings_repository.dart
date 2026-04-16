import '../models/app_settings.dart';
import '../services/storage_service.dart';
import 'settings_repository.dart';

class JsonSettingsRepository implements SettingsRepository {
  JsonSettingsRepository(this._storage);

  final StorageService _storage;

  @override
  Future<AppSettings> readSettings() => _storage.readSettings();

  @override
  Future<void> writeSettings(AppSettings settings) =>
      _storage.writeSettings(settings);

  @override
  Future<String> cacheBackgroundImage(String sourcePath) =>
      _storage.cacheBackgroundImage(sourcePath);

  @override
  Future<void> cleanupBackgroundImageCache({
    String? activePath,
    int maxFiles = 8,
  }) => _storage.cleanupBackgroundImageCache(
    activePath: activePath,
    maxFiles: maxFiles,
  );
}
