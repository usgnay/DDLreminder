import '../models/app_settings.dart';
import '../models/task.dart';
import 'mobile_widget_service.dart';

class MobileWidgetSyncService {
  MobileWidgetSyncService(this._widgetService);

  final MobileWidgetService _widgetService;
  String? _lastSignature;

  Future<void> syncIfNeeded({
    required List<Task> tasks,
    required AppSettings settings,
    required DateTime now,
  }) async {
    final snapshot = tasks
        .map(
          (task) =>
              '${task.id}:${task.completed}:${task.nextDueDate(now).toIso8601String()}',
        )
        .join('|');
    final signature =
        '${settings.language.name}:${settings.mobileAppBarColorValue}:$snapshot';
    if (_lastSignature == signature) {
      return;
    }
    _lastSignature = signature;
    await _widgetService.syncTasks(tasks: tasks, settings: settings, now: now);
  }
}
