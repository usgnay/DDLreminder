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
        ? task
              .nextDueDate(now)
              .difference(DateTime(now.year, now.month, now.day))
              .inDays
        : daysLeft;
    final urgency = _urgencyFor(
      effectiveDaysLeft,
      task.completed && !task.isRecurring,
      urgencyTintColor,
      urgencyOverlayOpacity,
    );
    final subtitle = _buildSubtitle(effectiveDaysLeft);
    final deadlineDate = task.isRecurring
        ? task.nextDueDate(now)
        : (task.oneOffDeadline ?? now);
    final dateText = DateFormat(
      'yyyy-MM-dd',
      language.localeCode,
    ).format(deadlineDate);
    final weekdayText = DateFormat(
      'EEE',
      language.localeCode,
    ).format(deadlineDate);
    final timeText = task.hasSpecificTime
        ? DateFormat('HH:mm', language.localeCode).format(deadlineDate)
        : null;
    final recurrenceLabel = task.isRecurring ? _recurrenceText(task) : null;
    final metaSegments = <String>[
      if (recurrenceLabel != null) recurrenceLabel,
      '$dateText $weekdayText',
      if (timeText != null) timeText,
      subtitle,
    ];
    final baseColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    final mutedColor = baseColor.withOpacity(.62);
    final titleColor = task.completed && !task.isRecurring
        ? mutedColor
        : baseColor;
    final textStyle = task.completed && !task.isRecurring
        ? Theme.of(context).textTheme.bodyMedium?.copyWith(
            decoration: TextDecoration.lineThrough,
            color: titleColor,
          )
        : Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: titleColor,
            fontWeight: urgency.highlightTitle
                ? FontWeight.w600
                : FontWeight.w500,
          );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: urgency.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(value: task.completed, onChanged: (_) => onToggle()),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metaSegments.join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: mutedColor, height: 1.25),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _TaskTrailing(
                task: task,
                effectiveDaysLeft: effectiveDaysLeft,
                urgency: urgency,
                baseColor: baseColor,
                language: language,
                onDelete: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSubtitle(int daysLeft) {
    if (task.isRecurring) {
      return tr(language, '还剩 $daysLeft 天', '$daysLeft day(s) left');
    }
    if (task.completed) {
      return tr(language, '已完成', 'Completed');
    }
    if (daysLeft < 0) {
      return tr(
        language,
        '已逾期 ${daysLeft.abs()} 天',
        'Overdue ${daysLeft.abs()} day(s)',
      );
    }
    return tr(language, '还剩 $daysLeft 天', '$daysLeft day(s) left');
  }

  String? _recurrenceText(Task task) {
    if (!task.isRecurring) {
      return null;
    }
    switch (task.recurrenceType) {
      case RecurrenceType.weekly:
        final labels = weekdayLabels(language);
        final index = ((task.recurrenceValue ?? 1) - 1).clamp(0, 6);
        return language == AppLanguage.zh
            ? '每周 ${labels[index]}'
            : 'Every ${labels[index]}';
      case RecurrenceType.monthly:
        final day = (task.recurrenceValue ?? 1).clamp(1, 31);
        return language == AppLanguage.zh ? '每月 $day 日' : 'Day $day each month';
      case RecurrenceType.none:
        return null;
    }
  }

  _TaskUrgencyStyle _urgencyFor(
    int daysLeft,
    bool completed,
    Color tintColor,
    double overlayOpacity,
  ) {
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
        background: tintColor.withOpacity(
          (overlayOpacity * .78).clamp(.03, .20),
        ),
      );
    }
    return const _TaskUrgencyStyle(
      accent: Color(0xFF314A64),
      background: Colors.transparent,
    );
  }
}

class _TaskTrailing extends StatelessWidget {
  const _TaskTrailing({
    required this.task,
    required this.effectiveDaysLeft,
    required this.urgency,
    required this.baseColor,
    required this.language,
    required this.onDelete,
  });

  final Task task;
  final int effectiveDaysLeft;
  final _TaskUrgencyStyle urgency;
  final Color baseColor;
  final AppLanguage language;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 76, maxWidth: 96),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (urgency.showWarningIcon)
            Icon(
              Icons.schedule_rounded,
              color: urgency.accent.withOpacity(.85),
              size: 18,
            )
          else if (task.completed && !task.isRecurring)
            const Icon(Icons.check_circle, color: Colors.green, size: 18)
          else
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4F8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  language == AppLanguage.zh
                      ? '$effectiveDaysLeft 天'
                      : '$effectiveDaysLeft d',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: baseColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: tr(language, '删除', 'Delete'),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
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
