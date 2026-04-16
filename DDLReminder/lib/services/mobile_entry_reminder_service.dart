import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/i18n.dart';
import '../models/app_settings.dart';
import '../models/task.dart';

class MobileEntryReminderService {
  String? _lastReminderSignature;

  void resetCycle() {
    _lastReminderSignature = null;
  }

  Future<void> maybeShowReminderDialog({
    required BuildContext context,
    required AppSettings settings,
    required List<Task> tasks,
    required DateTime now,
  }) async {
    if (!settings.mobileEntryReminderEnabled) {
      return;
    }

    final dueTasks = collectDueReminderTasks(
      tasks: tasks,
      settings: settings,
      now: now,
    );
    if (dueTasks.isEmpty) {
      _lastReminderSignature = null;
      return;
    }

    final signature =
        '${DateFormat('yyyy-MM-dd HH:mm').format(now)}:${dueTasks.map((task) => task.id).join(',')}';
    if (_lastReminderSignature == signature) {
      return;
    }
    _lastReminderSignature = signature;

    final language = settings.language;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(language, '即将到期提醒', 'Upcoming reminders')),
        content: SizedBox(
          width: 420,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogContext).size.height * .62,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: dueTasks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final task = dueTasks[index];
                final dueDate = task.nextDueDate(now);
                final dateLabel = DateFormat(
                  task.hasSpecificTime ? 'yyyy-MM-dd HH:mm' : 'yyyy-MM-dd EEE',
                  language.localeCode,
                ).format(dueDate);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(dialogContext)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(dialogContext).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$dateLabel  |  ${buildReminderMessage(task, now, settings)}',
                        style: Theme.of(dialogContext).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr(language, '知道了', 'Got it')),
          ),
        ],
      ),
    );
  }

  List<Task> collectDueReminderTasks({
    required List<Task> tasks,
    required AppSettings settings,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final leadHours = settings.mobileReminderLeadHours;
    return tasks
        .where((task) {
          if (task.completed && !task.isRecurring) {
            return false;
          }
          final due = task.nextDueDate(now);
          final dueDay = DateTime(due.year, due.month, due.day);

          if (!task.isRecurring && task.hasSpecificTime) {
            final reminderAt = due.subtract(Duration(hours: leadHours));
            return now.isAfter(reminderAt) &&
                now.isBefore(due.add(const Duration(minutes: 1)));
          }

          return !dueDay.isAfter(today) && dueDay == today;
        })
        .toList(growable: false)
      ..sort((a, b) => a.nextDueDate(now).compareTo(b.nextDueDate(now)));
  }

  String buildReminderMessage(Task task, DateTime now, AppSettings settings) {
    final language = settings.language;
    if (!task.isRecurring && task.hasSpecificTime) {
      final hours = settings.mobileReminderLeadHours;
      return tr(
        language,
        '已进入截止前 $hours 小时提醒时段',
        'Inside the $hours-hour reminder window',
      );
    }
    final daysLeft = task.daysLeft(now);
    if (daysLeft < 0) {
      return tr(
        language,
        '已逾期 ${daysLeft.abs()} 天',
        'Overdue ${daysLeft.abs()} day(s)',
      );
    }
    return tr(language, '今天到期', 'Due today');
  }
}
