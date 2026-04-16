import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/i18n.dart';
import '../../models/app_settings.dart';
import '../../models/task.dart';

class RecurringTaskList extends StatefulWidget {
  const RecurringTaskList({
    super.key,
    required this.tasks,
    required this.onDelete,
    required this.onTap,
    required this.accentColor,
    required this.surfaceColor,
    required this.urgencyTintColor,
    required this.urgencyOverlayOpacity,
    required this.onToggle,
    required this.language,
  });

  final List<Task> tasks;
  final void Function(Task task) onDelete;
  final void Function(Task task) onTap;
  final Color accentColor;
  final Color surfaceColor;
  final Color urgencyTintColor;
  final double urgencyOverlayOpacity;
  final void Function(Task task) onToggle;
  final AppLanguage language;

  @override
  State<RecurringTaskList> createState() => _RecurringTaskListState();
}

class _RecurringTaskListState extends State<RecurringTaskList> {
  static const int _collapsedCount = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sortedTasks = widget.tasks.toList(growable: false)
      ..sort((a, b) {
        final diff = a.nextDueDate(now).compareTo(b.nextDueDate(now));
        if (diff != 0) {
          return diff;
        }
        return a.title.compareTo(b.title);
      });
    final visibleTasks = _expanded
        ? sortedTasks
        : sortedTasks.take(_collapsedCount).toList(growable: false);
    final hasMore = sortedTasks.length > _collapsedCount;
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: widget.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.accentColor.withOpacity(.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tr(widget.language, '周期任务', 'Recurring'),
                  style: titleStyle,
                ),
              ),
              if (hasMore)
                TextButton.icon(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  label: Text(
                    tr(
                      widget.language,
                      _expanded ? '收起' : '展开',
                      _expanded ? 'Less' : 'More',
                    ),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(0, 32),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ...visibleTasks.map(
            (task) => _RecurringRow(
              task: task,
              today: today,
              language: widget.language,
              urgencyTintColor: widget.urgencyTintColor,
              urgencyOverlayOpacity: widget.urgencyOverlayOpacity,
              onDelete: widget.onDelete,
              onTap: widget.onTap,
              onToggle: widget.onToggle,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurringRow extends StatelessWidget {
  const _RecurringRow({
    required this.task,
    required this.today,
    required this.language,
    required this.urgencyTintColor,
    required this.urgencyOverlayOpacity,
    required this.onDelete,
    required this.onTap,
    required this.onToggle,
  });

  final Task task;
  final DateTime today;
  final AppLanguage language;
  final Color urgencyTintColor;
  final double urgencyOverlayOpacity;
  final void Function(Task task) onDelete;
  final void Function(Task task) onTap;
  final void Function(Task task) onToggle;

  @override
  Widget build(BuildContext context) {
    final due = task.nextDueDate(today);
    final days = due.difference(today).inDays;
    final dueText =
        '${DateFormat('MM-dd', language.localeCode).format(due)} ${DateFormat('EEE', language.localeCode).format(due)}';
    final urgency = _urgencyFor(days, urgencyTintColor, urgencyOverlayOpacity);
    final muted = Theme.of(context).textTheme.bodySmall?.color?.withOpacity(.7);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: urgency.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () => onTap(task),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Checkbox(
                  value: task.completed,
                  visualDensity: VisualDensity.compact,
                  onChanged: (_) => onToggle(task),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: urgency.highlightTitle
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _CompactBadge(
                label: _cycleLabel(task),
                foreground: const Color(0xFF2F4F4F),
                background: const Color(0xFFE4EFEC),
              ),
              const SizedBox(width: 6),
              _CompactBadge(
                label: language == AppLanguage.zh ? '$days 天' : '$days d',
                foreground: const Color(0xFF243041),
                background: const Color(0xFFF1F4F8),
              ),
              const SizedBox(width: 6),
              Text(
                dueText,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: muted),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                visualDensity: VisualDensity.compact,
                tooltip: tr(language, '删除', 'Delete'),
                onPressed: () => onDelete(task),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _cycleLabel(Task task) {
    switch (task.recurrenceType) {
      case RecurrenceType.weekly:
        final labels = weekdayLabels(language);
        final index = ((task.recurrenceValue ?? 1) - 1).clamp(0, 6);
        return labels[index];
      case RecurrenceType.monthly:
        final day = (task.recurrenceValue ?? 1).clamp(1, 31);
        return language == AppLanguage.zh ? '每月$day日' : 'M$day';
      case RecurrenceType.none:
        return '';
    }
  }

  _RecurringUrgencyStyle _urgencyFor(
    int daysLeft,
    Color tintColor,
    double overlayOpacity,
  ) {
    if (daysLeft <= 1) {
      return _RecurringUrgencyStyle(
        background: tintColor.withOpacity(overlayOpacity),
        highlightTitle: true,
      );
    }
    if (daysLeft <= 3) {
      return _RecurringUrgencyStyle(
        background: tintColor.withOpacity(
          (overlayOpacity * .78).clamp(.03, .20),
        ),
      );
    }
    return const _RecurringUrgencyStyle(background: Colors.transparent);
  }
}

class _CompactBadge extends StatelessWidget {
  const _CompactBadge({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RecurringUrgencyStyle {
  const _RecurringUrgencyStyle({
    required this.background,
    this.highlightTitle = false,
  });

  final Color background;
  final bool highlightTitle;
}
