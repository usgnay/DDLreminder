import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../models/task.dart';
import '../services/autostart_service.dart';
import '../services/bootstrap.dart';
import '../services/desktop_reminder_service.dart';
import '../services/font_service.dart';
import '../services/mobile_entry_reminder_service.dart';
import '../services/mobile_widget_service.dart';
import '../services/mobile_widget_sync_service.dart';
import '../services/settings_service.dart';
import '../services/system_shell_service.dart';
import '../services/task_service.dart';
import '../services/update_service.dart';

final serviceContainerProvider = Provider<ServiceContainer>((ref) {
  throw UnimplementedError('serviceContainerProvider must be overridden.');
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return ref.watch(serviceContainerProvider).settings;
});

final taskServiceProvider = Provider<TaskService>((ref) {
  return ref.watch(serviceContainerProvider).tasks;
});

final autostartServiceProvider = Provider<AutostartService>((ref) {
  return ref.watch(serviceContainerProvider).autostart;
});

final fontServiceProvider = Provider<FontService>((ref) {
  return ref.watch(serviceContainerProvider).fonts;
});

final systemShellServiceProvider = Provider<SystemShellService>((ref) {
  return ref.watch(serviceContainerProvider).systemShell;
});

final desktopReminderServiceProvider = Provider<DesktopReminderService>((ref) {
  return DesktopReminderService(ref.watch(systemShellServiceProvider));
});

final updateServiceProvider = Provider<UpdateService>((ref) {
  return ref.watch(serviceContainerProvider).updates;
});

final mobileWidgetServiceProvider = Provider<MobileWidgetService>((ref) {
  return MobileWidgetService();
});

final mobileWidgetSyncServiceProvider = Provider<MobileWidgetSyncService>((
  ref,
) {
  return MobileWidgetSyncService(ref.watch(mobileWidgetServiceProvider));
});

final mobileEntryReminderServiceProvider = Provider<MobileEntryReminderService>(
  (ref) {
    return MobileEntryReminderService();
  },
);

final settingsNotifierProvider = ChangeNotifierProvider<SettingsService>((ref) {
  return ref.watch(settingsServiceProvider);
});

final taskNotifierProvider = ChangeNotifierProvider<TaskService>((ref) {
  return ref.watch(taskServiceProvider);
});

final appSettingsProvider = Provider<AppSettings>((ref) {
  return ref.watch(settingsNotifierProvider).value;
});

final taskListProvider = Provider<List<Task>>((ref) {
  return ref.watch(taskNotifierProvider).tasks.toList(growable: false);
});

final oneOffTasksProvider = Provider<List<Task>>((ref) {
  return ref
      .watch(taskListProvider)
      .where((task) => !task.isRecurring)
      .toList(growable: false);
});

final recurringTasksProvider = Provider<List<Task>>((ref) {
  return ref
      .watch(taskListProvider)
      .where((task) => task.isRecurring)
      .toList(growable: false);
});
