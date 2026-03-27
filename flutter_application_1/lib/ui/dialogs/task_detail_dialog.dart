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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: widget.task.description,
    );
    _deadline = widget.task.deadline;
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
                  labelText: tr(lang, '任务简称', 'Task title'),
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
              if (widget.task.isRecurring) ...[
                const SizedBox(height: 10),
                Text(
                  _recurrenceLabel(widget.task, lang),
                  style: Theme.of(context).textTheme.bodySmall,
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
    if (picked != null) {
      setState(
        () => _deadline = DateTime(picked.year, picked.month, picked.day),
      );
    }
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final updatedTask = widget.task.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      deadline: DateTime(_deadline.year, _deadline.month, _deadline.day),
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
          ? '周期: 每周 ${names[index]}'
          : 'Repeats: every ${names[index]}';
    case RecurrenceType.monthly:
      final day = (task.recurrenceValue ?? 1).clamp(1, 31);
      return language == AppLanguage.zh
          ? '周期: 每月 $day 日'
          : 'Repeats: day $day each month';
    case RecurrenceType.none:
      return '';
  }
}
