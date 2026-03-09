import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/app_settings.dart';
import '../models/task.dart';
import 'autostart_service.dart';
import 'settings_service.dart';
import 'storage_service.dart';
import 'task_service.dart';

class ServiceContainer {
  ServiceContainer({
    required this.settings,
    required this.tasks,
    required this.autostart,
  });

  final SettingsService settings;
  final TaskService tasks;
  final AutostartService autostart;
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

  return ServiceContainer(
    settings: settingsService,
    tasks: taskService,
    autostart: autostartService,
  );
}

List<Task> filterDueSoon(Iterable<Task> tasks, AppSettings settings, DateTime today) {
  return tasks
      .where((task) {
        if (task.completed) {
          return false;
        }
        final threshold = task.isRecurring
            ? (task.recurrenceReminderDays ??
                (task.recurrenceType == RecurrenceType.weekly
                    ? settings.weeklyReminderDays
                    : settings.monthlyReminderDays))
            : settings.reminderThresholdDays;
        final diff = task.daysLeft(today);
        return diff <= threshold;
      })
      .toList(growable: false);
}
