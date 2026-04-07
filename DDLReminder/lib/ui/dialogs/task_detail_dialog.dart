import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/i18n.dart';
import '../../models/app_settings.dart';
import '../../models/task.dart';

Future<Task?> showTaskDetailDialog(
  BuildContext context,
  Task task,
  AppLanguage language,
) {
  return showDialog<Task>(
    context: context,
    builder: (_) => _EditableTaskDialog(task: task, language: language),
  );
}

class _EditableTaskDialog extends StatefulWidget {
  const _EditableTaskDialog({required this.task, required this.language});

  final Task task;
  final AppLanguage language;

  @override
  State<_EditableTaskDialog> createState() => _EditableTaskDialogState();
}

class _EditableTaskDialogState extends State<_EditableTaskDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final _formKey = GlobalKey<FormState>();
  late DateTime _deadline;
  late bool _hasSpecificTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: widget.task.description,
    );
    _deadline = widget.task.oneOffDeadline ?? DateTime.now();
    _hasSpecificTime = widget.task.hasSpecificTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;
    final formatter = DateFormat('yyyy-MM-dd', lang.localeCode);
    final timeFormatter = DateFormat('HH:mm', lang.localeCode);
    final nextDue = widget.task.nextDueDate(DateTime.now());

    return AlertDialog(
      title: Text(tr(lang, '编辑任务', 'Edit task')),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: tr(lang, '任务标题', 'Task title'),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? tr(lang, '请输入任务名称', 'Please enter a task name')
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: tr(lang, '任务描述', 'Description'),
                ),
                minLines: 2,
                maxLines: 4,
              ),
              if (widget.task.isRecurring) ...[
                const SizedBox(height: 12),
                Text(
                  _recurrenceLabel(widget.task, lang),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  tr(
                    lang,
                    '下次截止：${formatter.format(nextDue)} ${DateFormat('EEE', lang.localeCode).format(nextDue)}',
                    'Next due: ${formatter.format(nextDue)} ${DateFormat('EEE', lang.localeCode).format(nextDue)}',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ] else ...[
                const SizedBox(height: 12),
                Text(
                  tr(lang, '截止日期', 'Deadline'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: Text(formatter.format(_deadline))),
                    TextButton(
                      onPressed: _pickDate,
                      child: Text(tr(lang, '选择日期', 'Pick date')),
                    ),
                  ],
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _hasSpecificTime,
                  onChanged: (value) async {
                    setState(() {
                      _hasSpecificTime = value;
                      if (!value) {
                        _deadline = DateTime(
                          _deadline.year,
                          _deadline.month,
                          _deadline.day,
                        );
                      }
                    });
                    if (value) {
                      await _pickTime();
                    }
                  },
                  title: Text(tr(lang, '具体到时间', 'Specific time')),
                  subtitle: Text(
                    tr(
                      lang,
                      '开启后在任务标题下方显示具体时间',
                      'Show the exact due time under the task title',
                    ),
                  ),
                ),
                if (_hasSpecificTime)
                  Row(
                    children: [
                      Expanded(child: Text(timeFormatter.format(_deadline))),
                      TextButton(
                        onPressed: _pickTime,
                        child: Text(tr(lang, '选择时间', 'Pick time')),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr(lang, '取消', 'Cancel')),
        ),
        FilledButton(onPressed: _save, child: Text(tr(lang, '保存', 'Save'))),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      locale: Locale(widget.language == AppLanguage.zh ? 'zh' : 'en'),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _deadline = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _hasSpecificTime ? _deadline.hour : 0,
        _hasSpecificTime ? _deadline.minute : 0,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _deadline.hour, minute: _deadline.minute),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _deadline = DateTime(
        _deadline.year,
        _deadline.month,
        _deadline.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final updatedTask = widget.task.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      deadline: widget.task.isRecurring
          ? null
          : DateTime(
              _deadline.year,
              _deadline.month,
              _deadline.day,
              _hasSpecificTime ? _deadline.hour : 0,
              _hasSpecificTime ? _deadline.minute : 0,
            ),
      hasSpecificTime: widget.task.isRecurring ? false : _hasSpecificTime,
      clearDeadline: widget.task.isRecurring,
    );
    Navigator.pop(context, updatedTask);
  }
}

String _recurrenceLabel(Task task, AppLanguage language) {
  switch (task.recurrenceType) {
    case RecurrenceType.weekly:
      final names = weekdayLabels(language);
      final index = ((task.recurrenceValue ?? 1) - 1).clamp(0, 6);
      return language == AppLanguage.zh
          ? '周期：每周 ${names[index]}'
          : 'Repeats: every ${names[index]}';
    case RecurrenceType.monthly:
      final day = (task.recurrenceValue ?? 1).clamp(1, 31);
      return language == AppLanguage.zh
          ? '周期：每月 $day 日'
          : 'Repeats: day $day each month';
    case RecurrenceType.none:
      return '';
  }
}
