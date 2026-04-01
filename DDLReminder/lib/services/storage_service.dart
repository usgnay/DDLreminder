import 'dart:convert';
import 'dart:io';

import '../models/app_settings.dart';
import '../models/task.dart';

class StorageService {
  StorageService({
    required this.tasksFile,
    required this.settingsFile,
    required this.dataDir,
  });

  final File tasksFile;
  final File settingsFile;
  final Directory dataDir;

  Directory get backgroundCacheDir => Directory('${dataDir.path}/background_cache');

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

  Future<String> cacheBackgroundImage(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Background image not found', sourcePath);
    }

    if (!await backgroundCacheDir.exists()) {
      await backgroundCacheDir.create(recursive: true);
    }

    final extension = sourceFile.path.contains('.') ? sourceFile.path.substring(sourceFile.path.lastIndexOf('.')) : '.img';
    final filename = 'bg_${DateTime.now().microsecondsSinceEpoch}$extension';
    final cachedFile = File('${backgroundCacheDir.path}/$filename');
    await sourceFile.copy(cachedFile.path);
    await cleanupBackgroundImageCache(activePath: cachedFile.path);
    return cachedFile.path;
  }

  Future<void> cleanupBackgroundImageCache({
    String? activePath,
    int maxFiles = 8,
  }) async {
    if (!await backgroundCacheDir.exists()) {
      return;
    }

    final entities = await backgroundCacheDir.list().where((entity) => entity is File).cast<File>().toList();
    entities.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    final keep = <String>{};
    if (activePath != null && activePath.startsWith(backgroundCacheDir.path)) {
      keep.add(activePath);
    }

    for (final file in entities) {
      if (keep.length >= maxFiles) {
        break;
      }
      keep.add(file.path);
    }

    for (final file in entities) {
      if (!keep.contains(file.path)) {
        await file.delete();
      }
    }
  }
}
