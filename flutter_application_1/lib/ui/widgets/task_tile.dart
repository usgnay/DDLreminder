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
    required this.urgencyTintColor,
    required this.urgencyOverlayOpacity,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
    required this.language,
  });

  final Task task;
  final int daysLeft;
  final Color urgencyTintColor;
  final double urgencyOverlayOpacity;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final effectiveDaysLeft = task.isRecurring
        ? task.nextDueDate(now).difference(DateTime(now.year, now.month, now.day)).inDays
        : daysLeft;
    final urgency = _urgencyFor(
      effectiveDaysLeft,
      task.completed && !task.isRecurring,
      urgencyTintColor,
      urgencyOverlayOpacity,
    );
    final subtitle = _buildSubtitle(effectiveDaysLeft);
    final formatter = DateFormat('yyyy-MM-dd');
    final deadlineDate = task.isRecurring ? task.nextDueDate(now) : (task.oneOffDeadline ?? now);
    final deadlineText = formatter.format(deadlineDate);
    final recurrenceLabel = task.isRecurring ? _recurrenceText(task) : null;
    final baseColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    final mutedColor = baseColor.withOpacity(.62);
    final titleColor = task.completed && !task.isRecurring ? mutedColor : baseColor;
    final textStyle = task.completed && !task.isRecurring
        ? Theme.of(context).textTheme.bodyMedium?.copyWith(
            decoration: TextDecoration.lineThrough,
            color: titleColor,
          )
        : Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: titleColor,
            fontWeight: urgency.highlightTitle ? FontWeight.w600 : FontWeight.w500,
          );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: urgency.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: Checkbox(value: task.completed, onChanged: (_) => onToggle()),
        title: Text(task.title, style: textStyle),
        subtitle: Text(
          '${recurrenceLabel != null ? '$recurrenceLabel · ' : ''}$deadlineText · $subtitle',
          style: TextStyle(color: mutedColor),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (urgency.showWarningIcon)
              Icon(Icons.schedule_rounded, color: urgency.accent.withOpacity(.85), size: 18)
            else if (task.completed && !task.isRecurring)
              const Icon(Icons.check_circle, color: Colors.green, size: 18)
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4F8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  language == AppLanguage.zh ? '$effectiveDaysLeft 天' : '$effectiveDaysLeft d',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: baseColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: tr(language, '删除', 'Delete'),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle(int daysLeft) {
    if (task.isRecurring) {
      return tr(language, '剩余 $daysLeft 天', '$daysLeft day(s) left');
    }
    if (task.completed) {
      return tr(language, '已完成', 'Completed');
    }
    if (daysLeft < 0) {
      return tr(language, '已逾期 ${daysLeft.abs()} 天', 'Overdue ${daysLeft.abs()} day(s)');
    }
    return tr(language, '剩余 $daysLeft 天', '$daysLeft day(s) left');
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

  _TaskUrgencyStyle _urgencyFor(int daysLeft, bool completed, Color tintColor, double overlayOpacity) {
    if (completed) {
      return const _TaskUrgencyStyle(
        accent: Color(0xFF5F6C7B),
        background: Colors.transparent,
      );
    }
    if (daysLeft <= 1) {
      return _TaskUrgencyStyle(
        accent: tintColor.withOpacity(.95),
        background: tintColor.withOpacity(overlayOpacity),
        showWarningIcon: false,
        highlightTitle: true,
      );
    }
    if (daysLeft <= 3) {
      return _TaskUrgencyStyle(
        accent: tintColor.withOpacity(.82),
        background: tintColor.withOpacity((overlayOpacity * .78).clamp(.03, .20)),
      );
    }
    return const _TaskUrgencyStyle(
      accent: Color(0xFF314A64),
      background: Colors.transparent,
    );
  }
}

class _TaskUrgencyStyle {
  const _TaskUrgencyStyle({
    required this.accent,
    required this.background,
    this.showWarningIcon = false,
    this.highlightTitle = false,
  });

  final Color accent;
  final Color background;
  final bool showWarningIcon;
  final bool highlightTitle;
}
