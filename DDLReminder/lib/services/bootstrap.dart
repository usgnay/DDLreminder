import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';
import '../models/app_settings.dart';
import '../repositories/isar_settings_repository.dart';
import '../repositories/isar_task_repository.dart';
import '../repositories/json_settings_repository.dart';
import '../repositories/json_task_repository.dart';
import 'autostart_service.dart';
import 'font_service.dart';
import 'settings_service.dart';
import 'storage_service.dart';
import 'system_shell_service.dart';
import 'task_service.dart';
import 'update_service.dart';

class ServiceContainer {
  ServiceContainer({
    required this.settings,
    required this.tasks,
    required this.autostart,
    required this.fonts,
    required this.systemShell,
    required this.updates,
  });

  final SettingsService settings;
  final TaskService tasks;
  final AutostartService autostart;
  final FontService fonts;
  final SystemShellService systemShell;
  final UpdateService updates;
}

Future<ServiceContainer> bootstrapApp() async {
  final dir = await getApplicationSupportDirectory();
  final dataDir = Directory('${dir.path}/task_widget');
  if (!await dataDir.exists()) {
    await dataDir.create(recursive: true);
  }

  final storage = StorageService(
    tasksFile: File('${dataDir.path}/tasks.json'),
    settingsFile: File('${dataDir.path}/settings.json'),
    dataDir: dataDir,
  );
  final jsonSettingsRepository = JsonSettingsRepository(storage);
  final jsonTaskRepository = JsonTaskRepository(storage);
  final database = await AppDatabase.open(directory: dataDir.path);
  final settingsRepository = IsarSettingsRepository(
    database,
    jsonSettingsRepository,
  );
  final taskRepository = IsarTaskRepository(database);
  await _migrateJsonDataIfNeeded(
    taskRepository: taskRepository,
    settingsRepository: settingsRepository,
    jsonTaskRepository: jsonTaskRepository,
    jsonSettingsRepository: jsonSettingsRepository,
  );

  final settingsService = SettingsService(settingsRepository);
  await settingsService.load();
  await settingsService.cleanupBackgroundImageCache();

  final taskService = TaskService(taskRepository);
  await taskService.load();

  final autostartService = AutostartService();
  if (settingsService.value.autoLaunch) {
    await autostartService.apply(enable: true);
  }

  final fontService = FontService();
  final systemShellService = SystemShellService();
  final updateService = UpdateService();

  return ServiceContainer(
    settings: settingsService,
    tasks: taskService,
    autostart: autostartService,
    fonts: fontService,
    systemShell: systemShellService,
    updates: updateService,
  );
}

Future<void> _migrateJsonDataIfNeeded({
  required IsarTaskRepository taskRepository,
  required IsarSettingsRepository settingsRepository,
  required JsonTaskRepository jsonTaskRepository,
  required JsonSettingsRepository jsonSettingsRepository,
}) async {
  final existingTasks = await taskRepository.readTasks();
  if (existingTasks.isEmpty) {
    final legacyTasks = await jsonTaskRepository.readTasks();
    if (legacyTasks.isNotEmpty) {
      await taskRepository.writeTasks(legacyTasks);
    }
  }

  final existingSettings = await settingsRepository.readSettings();
  final defaults = AppSettings.defaults();
  final shouldMigrateSettings =
      existingSettings.toJson().toString() == defaults.toJson().toString();
  if (shouldMigrateSettings) {
    final legacySettings = await jsonSettingsRepository.readSettings();
    if (legacySettings.toJson().toString() != defaults.toJson().toString()) {
      await settingsRepository.writeSettings(legacySettings);
    }
  }
}
