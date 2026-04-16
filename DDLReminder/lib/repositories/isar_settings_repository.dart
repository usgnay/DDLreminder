import 'dart:convert';

import '../database/app_database.dart';
import '../database/settings_record.dart';
import '../models/app_settings.dart';
import 'settings_repository.dart';

class IsarSettingsRepository implements SettingsRepository {
  IsarSettingsRepository(this._database, this._fallback);

  final AppDatabase _database;
  final SettingsRepository _fallback;

  @override
  Future<AppSettings> readSettings() async {
    final record = await _database.isar.settingsRecords.get(0);
    if (record == null) {
      return AppSettings.defaults();
    }
    return AppSettings.fromJson(
      Map<String, dynamic>.from(jsonDecode(record.payloadJson) as Map),
    );
  }

  @override
  Future<void> writeSettings(AppSettings settings) async {
    await _database.isar.writeTxn(() async {
      await _database.isar.settingsRecords.put(
        SettingsRecord()
          ..id = 0
          ..payloadJson = jsonEncode(settings.toJson()),
      );
    });
  }

  @override
  Future<String> cacheBackgroundImage(String sourcePath) =>
      _fallback.cacheBackgroundImage(sourcePath);

  @override
  Future<void> cleanupBackgroundImageCache({
    String? activePath,
    int maxFiles = 8,
  }) => _fallback.cleanupBackgroundImageCache(
    activePath: activePath,
    maxFiles: maxFiles,
  );
}
