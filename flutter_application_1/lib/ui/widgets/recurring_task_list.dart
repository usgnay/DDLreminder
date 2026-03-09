import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/task.dart';

class RecurringTaskList extends StatelessWidget {
  const RecurringTaskList({
    super.key,
    required this.tasks,
    required this.onDelete,
    required this.onTap,
    required this.accentColor,
  });

  final List<Task> tasks;
  final void Function(Task task) onDelete;
  final void Function(Task task) onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final weekly = tasks.where((task) => task.recurrenceType == RecurrenceType.weekly).toList(growable: false);
    final monthly = tasks.where((task) => task.recurrenceType == RecurrenceType.monthly).toList(growable: false);
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
          const Text('周期任务', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (weekly.isNotEmpty) _RecurringSection(label: '每周提醒', tasks: weekly, onDelete: onDelete, onTap: onTap),
          if (weekly.isNotEmpty && monthly.isNotEmpty) const Divider(height: 20),
          if (monthly.isNotEmpty) _RecurringSection(label: '每月提醒', tasks: monthly, onDelete: onDelete, onTap: onTap),
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
  });

  final String label;
  final List<Task> tasks;
  final void Function(Task task) onDelete;
  final void Function(Task task) onTap;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MM-dd');
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        ...tasks.map((task) {
          final due = task.nextDueDate(now);
          final days = task.daysLeft(now);
          final subtitle = days >= 0 ? '剩余 $days 天' : '已逾期 ${days.abs()} 天';
          return ListTile(
            dense: true,
            onTap: () => onTap(task),
            contentPadding: EdgeInsets.zero,
            title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${formatter.format(due)} · $subtitle'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '删除',
              onPressed: () => onDelete(task),
            ),
          );
        }),
      ],
    );
  }
}
