import '../models/app_settings.dart';
import '../models/task.dart';

List<Task> filterDueSoon(
  Iterable<Task> tasks,
  AppSettings settings,
  DateTime today,
) {
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
