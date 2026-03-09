import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/i18n.dart';
import '../../models/app_settings.dart';
import '../../models/task.dart';

void showTaskDetailDialog(BuildContext context, Task task, AppLanguage language) {
  final formatter = DateFormat('yyyy-MM-dd', language.localeCode);
  final now = DateTime.now();
  final days = task.daysLeft(now);
  final dueDate = task.nextDueDate(now);
  final overdue = days < 0;
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(task.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.isRecurring
                ? tr(language, '下次提醒: ${formatter.format(dueDate)}', 'Next reminder: ${formatter.format(dueDate)}')
                : tr(language, '截止日期: ${formatter.format(task.deadline)}', 'Due date: ${formatter.format(task.deadline)}'),
          ),
          if (task.isRecurring) ...[
            const SizedBox(height: 4),
            Text(_recurrenceLabel(task, language)),
          ],
          const SizedBox(height: 4),
          Text(
            overdue
                ? tr(language, '状态: 已逾期', 'Status: overdue')
                : (task.completed
                    ? tr(language, '状态: 已完成', 'Status: done')
                    : tr(language, '状态: 进行中', 'Status: in progress')),
          ),
          const SizedBox(height: 8),
          Text(
            days >= 0
                ? tr(language, '剩余天数: $days', 'Days remaining: $days')
                : tr(language, '剩余天数: 已超期 ${days.abs()} 天', 'Days remaining: overdue by ${days.abs()} day(s)'),
          ),
          const SizedBox(height: 12),
          Text(task.description.isEmpty
              ? tr(language, '暂无详细描述', 'No additional description')
              : task.description),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(tr(language, '关闭', 'Close'))),
      ],
    ),
  );
}

String _recurrenceLabel(Task task, AppLanguage language) {
  switch (task.recurrenceType) {
    case RecurrenceType.weekly:
      final names = weekdayLabels(language);
      final index = ((task.recurrenceValue ?? 1) - 1).clamp(0, 6);
      return language == AppLanguage.zh ? '周期: 每周 ${names[index]}' : 'Repeats: every ${names[index]}';
    case RecurrenceType.monthly:
      final day = (task.recurrenceValue ?? 1).clamp(1, 31);
      return language == AppLanguage.zh ? '周期: 每月 $day 日' : 'Repeats: day $day each month';
    case RecurrenceType.none:
      return '';
  }
}
