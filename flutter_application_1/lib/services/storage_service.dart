import 'dart:convert';
import 'dart:io';

import '../models/app_settings.dart';
import '../models/task.dart';

class StorageService {
  StorageService({required this.tasksFile, required this.settingsFile});

  final File tasksFile;
  final File settingsFile;

  Future<List<Task>> readTasks() async {
    if (!await tasksFile.exists()) {
      return [];
    }
    final raw = await tasksFile.readAsString();
    if (raw.trim().isEmpty) {
      return [];
    }
    final payload = jsonDecode(raw) as List<dynamic>;
    return payload
      .map((node) => Task.fromJson(Map<String, dynamic>.from(node as Map)))
      .toList(growable: false);
  }

  Future<void> writeTasks(List<Task> tasks) async {
    final data = tasks.map((task) => task.toJson()).toList(growable: false);
    await tasksFile.writeAsString(jsonEncode(data), flush: true);
  }

  Future<AppSettings> readSettings() async {
    if (!await settingsFile.exists()) {
      return AppSettings.defaults();
    }
    final raw = await settingsFile.readAsString();
    if (raw.trim().isEmpty) {
      return AppSettings.defaults();
    }
    return AppSettings.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
  }

  Future<void> writeSettings(AppSettings settings) async {
    await settingsFile.writeAsString(jsonEncode(settings.toJson()), flush: true);
  }
}
