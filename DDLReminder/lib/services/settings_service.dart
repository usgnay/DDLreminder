import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../repositories/settings_repository.dart';

class SettingsService extends ValueNotifier<AppSettings> {
  SettingsService(this._repository) : super(AppSettings.defaults());

  final SettingsRepository _repository;

  Future<void> load() async {
    value = await _repository.readSettings();
  }

  Future<void> update(AppSettings next) async {
    value = next;
    await _repository.writeSettings(next);
    await _repository.cleanupBackgroundImageCache(
      activePath: next.backgroundImagePath,
    );
  }

  Future<String> cacheBackgroundImage(String sourcePath) =>
      _repository.cacheBackgroundImage(sourcePath);

  Future<void> cleanupBackgroundImageCache() => _repository
      .cleanupBackgroundImageCache(activePath: value.backgroundImagePath);
}
