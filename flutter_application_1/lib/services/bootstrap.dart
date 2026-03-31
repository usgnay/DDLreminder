import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/app_settings.dart';
import '../models/task.dart';
import 'autostart_service.dart';
import 'font_service.dart';
import 'settings_service.dart';
import 'storage_service.dart';
import 'system_shell_service.dart';
import 'task_service.dart';

class ServiceContainer {
  ServiceContainer({
    required this.settings,
    required this.tasks,
    required this.autostart,
    required this.fonts,
    required this.systemShell,
  });

  final SettingsService settings;
  final TaskService tasks;
  final AutostartService autostart;
  final FontService fonts;
  final SystemShellService systemShell;
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
  );

  final settingsService = SettingsService(storage);
  await settingsService.load();

  final taskService = TaskService(storage);
  await taskService.load();

  final autostartService = AutostartService();
  if (settingsService.value.autoLaunch) {
    await autostartService.apply(enable: true);
  }

  final fontService = FontService();
  final systemShellService = SystemShellService();

  return ServiceContainer(
    settings: settingsService,
    tasks: taskService,
    autostart: autostartService,
    fonts: fontService,
    systemShell: systemShellService,
  );
}

List<Task> filterDueSoon(Iterable<Task> tasks, AppSettings settings, DateTime today) {
  return tasks
      .where((task) {
        if (!task.isRecurring && task.completed) {
          return false;
        }
        final threshold = task.isRecurring
            ? (task.recurrenceReminderDays ??
                (task.recurrenceType == RecurrenceType.weekly
                    ? settings.weeklyReminderDays
                    : settings.monthlyReminderDays))
            : settings.reminderThresholdDays;
        final diff = task.daysLeft(today);
        if (task.isRecurring && diff < 0) {
          return false;
        }
        return diff <= threshold;
      })
      .toList(growable: false);
}
