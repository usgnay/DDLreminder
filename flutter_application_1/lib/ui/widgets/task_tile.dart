import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/i18n.dart';
import '../../models/app_settings.dart';
import '../../models/task.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.daysLeft,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
    required this.language,
  });

  final Task task;
  final int daysLeft;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final overdue = daysLeft < 0;
    final subtitle = task.completed
        ? tr(language, '已完成', 'Completed')
        : overdue
            ? tr(language, '已逾期 ${daysLeft.abs()} 天', 'Overdue ${daysLeft.abs()} day(s)')
            : tr(language, '剩余 $daysLeft 天', '$daysLeft day(s) left');
    final formatter = DateFormat('yyyy-MM-dd');
    final deadlineDate = task.isRecurring ? task.nextDueDate(now) : task.deadline;
    final deadlineText = formatter.format(deadlineDate);
    final recurrenceLabel = task.isRecurring ? _recurrenceText(task) : null;
    final baseColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    final mutedColor = baseColor.withOpacity(.6);
    final textStyle = task.completed
        ? Theme.of(context).textTheme.bodyMedium?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: mutedColor,
            )
        : Theme.of(context).textTheme.bodyMedium;

    final showOverdue = overdue && !task.completed;

    return ListTile(
      onTap: onTap,
      dense: true,
      leading: Checkbox(value: task.completed, onChanged: (_) => onToggle()),
      title: Text(task.title, style: textStyle),
      subtitle: Text(
        '${recurrenceLabel != null ? '$recurrenceLabel · ' : ''}$deadlineText · $subtitle',
        style: TextStyle(color: showOverdue ? Colors.redAccent : mutedColor),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showOverdue)
            const Icon(Icons.error_outline, color: Colors.redAccent)
          else if (task.completed)
            const Icon(Icons.check_circle, color: Colors.green)
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                language == AppLanguage.zh ? '$daysLeft 天' : '$daysLeft day(s)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: tr(language, '删除', 'Delete'),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  String? _recurrenceText(Task task) {
    if (!task.isRecurring) {
      return null;
    }
    switch (task.recurrenceType) {
      case RecurrenceType.weekly:
        final labels = weekdayLabels(language);
        final index = ((task.recurrenceValue ?? 1) - 1).clamp(0, 6);
        return language == AppLanguage.zh ? '每周 ${labels[index]}' : 'Every ${labels[index]}';
      case RecurrenceType.monthly:
        final day = (task.recurrenceValue ?? 1).clamp(1, 31);
        return language == AppLanguage.zh ? '每月 $day 日' : 'Day $day each month';
      case RecurrenceType.none:
        return null;
    }
  }
}
