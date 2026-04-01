import 'package:ddl_reminder/models/app_settings.dart';
import 'package:ddl_reminder/models/task.dart';
import 'package:ddl_reminder/services/bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Recurring tasks', () {
    test('next due date is projected from the current day', () {
      final task = Task.recurring(
        id: 'weekly-1',
        title: 'Weekly report',
        description: '',
        completed: true,
        recurrenceType: RecurrenceType.weekly,
        recurrenceValue: DateTime.monday,
        recurrenceReminderDays: 1,
      );

      expect(task.nextDueDate(DateTime(2026, 4, 2)), DateTime(2026, 4, 6));
      expect(task.daysLeft(DateTime(2026, 4, 2)), 4);
    });

    test('completed recurring tasks can still enter due soon reminders', () {
      final recurringTask = Task.recurring(
        id: 'monthly-1',
        title: 'Monthly billing',
        description: '',
        completed: true,
        recurrenceType: RecurrenceType.monthly,
        recurrenceValue: 5,
        recurrenceReminderDays: 3,
      );

      final reminders = filterDueSoon(
        [recurringTask],
        AppSettings.defaults(),
        DateTime(2026, 4, 2),
      );

      expect(reminders.map((task) => task.id), contains('monthly-1'));
    });

    test('completed one-off tasks stay out of due soon reminders', () {
      final regularTask = Task.oneOff(
        id: 'regular-1',
        title: 'One-off task',
        description: '',
        deadline: DateTime(2026, 4, 3),
        completed: true,
      );

      final reminders = filterDueSoon(
        [regularTask],
        AppSettings.defaults(),
        DateTime(2026, 4, 2),
      );

      expect(reminders, isEmpty);
    });
  });
}
