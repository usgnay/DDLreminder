import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/i18n.dart';
import '../../models/app_settings.dart';
import '../../models/task.dart';

class RecurringTaskList extends StatelessWidget {
  const RecurringTaskList({
    super.key,
    required this.tasks,
    required this.onDelete,
    required this.onTap,
    required this.accentColor,
    required this.onToggle,
    required this.language,
  });

  final List<Task> tasks;
  final void Function(Task task) onDelete;
  final void Function(Task task) onTap;
  final Color accentColor;
  final void Function(Task task) onToggle;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final weekly = tasks.where((task) => task.recurrenceType == RecurrenceType.weekly).toList(growable: false);
    final monthly = tasks.where((task) => task.recurrenceType == RecurrenceType.monthly).toList(growable: false);
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w700);
    if (weekly.isEmpty && monthly.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(language, '周期任务', 'Recurring tasks'),
            style: titleStyle,
          ),
          const SizedBox(height: 8),
          if (weekly.isNotEmpty)
            _RecurringSection(
              label: tr(language, '每周提醒', 'Weekly'),
              tasks: weekly,
              onDelete: onDelete,
              onTap: onTap,
              onToggle: onToggle,
              language: language,
            ),
          if (weekly.isNotEmpty && monthly.isNotEmpty) const Divider(height: 20),
          if (monthly.isNotEmpty)
            _RecurringSection(
              label: tr(language, '每月提醒', 'Monthly'),
              tasks: monthly,
              onDelete: onDelete,
              onTap: onTap,
              onToggle: onToggle,
              language: language,
            ),
        ],
      ),
    );
  }
}

class _RecurringSection extends StatelessWidget {
  const _RecurringSection({
    required this.label,
    required this.tasks,
    required this.onDelete,
    required this.onTap,
    required this.onToggle,
    required this.language,
  });

  final String label;
  final List<Task> tasks;
  final void Function(Task task) onDelete;
  final void Function(Task task) onTap;
  final void Function(Task task) onToggle;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MM-dd', language.localeCode);
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        ...tasks.map((task) {
          final due = task.nextDueDate(now);
          final days = task.daysLeft(now);
          final subtitle = days >= 0
              ? tr(language, '剩余 $days 天', '$days day(s) left')
              : tr(language, '已逾期 ${days.abs()} 天', 'Overdue ${days.abs()} day(s)');
          return ListTile(
            dense: true,
            onTap: () => onTap(task),
            contentPadding: EdgeInsets.zero,
            leading: Checkbox(
              value: task.completed,
              onChanged: (_) => onToggle(task),
            ),
            title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${formatter.format(due)} · $subtitle'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: tr(language, '删除', 'Delete'),
              onPressed: () => onDelete(task),
            ),
          );
        }),
      ],
    );
  }
}
