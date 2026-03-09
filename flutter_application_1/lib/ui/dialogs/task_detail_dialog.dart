import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/task.dart';

void showTaskDetailDialog(BuildContext context, Task task) {
  final formatter = DateFormat('yyyy-MM-dd');
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
          Text(task.isRecurring ? '下次提醒: ${formatter.format(dueDate)}' : '截止日期: ${formatter.format(task.deadline)}'),
          if (task.isRecurring) ...[
            const SizedBox(height: 4),
            Text(_recurrenceLabel(task)),
          ],
          const SizedBox(height: 4),
          Text(overdue ? '状态: 已逾期' : (task.completed ? '状态: 已完成' : '状态: 进行中')),
          const SizedBox(height: 8),
          Text('剩余天数: ${days >= 0 ? days : '已超期 ${days.abs()} 天'}'),
          const SizedBox(height: 12),
          Text(task.description.isEmpty ? '暂无详细描述' : task.description),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
      ],
    ),
  );
}

String _recurrenceLabel(Task task) {
  switch (task.recurrenceType) {
    case RecurrenceType.weekly:
      const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      final index = ((task.recurrenceValue ?? 1) - 1).clamp(0, 6);
      return '周期: 每周 ${names[index]}';
    case RecurrenceType.monthly:
      final day = (task.recurrenceValue ?? 1).clamp(1, 31);
      return '周期: 每月 $day 日';
    case RecurrenceType.none:
      return '';
  }
}
