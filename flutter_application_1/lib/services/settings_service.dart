import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import 'storage_service.dart';

class SettingsService extends ValueNotifier<AppSettings> {
  SettingsService(this._storage) : super(AppSettings.defaults());

  final StorageService _storage;

  Future<void> load() async {
    value = await _storage.readSettings();
  }

  Future<void> update(AppSettings next) async {
    value = next;
    await _storage.writeSettings(next);
  }
}
