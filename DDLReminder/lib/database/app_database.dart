import 'package:isar_community/isar.dart';

import 'settings_record.dart';
import 'task_record.dart';

class AppDatabase {
  AppDatabase._(this.isar);

  final Isar isar;

  static Future<AppDatabase> open({required String directory}) async {
    final isar = await Isar.open(
      [TaskRecordSchema, SettingsRecordSchema],
      directory: directory,
      inspector: false,
    );
    return AppDatabase._(isar);
  }
}
