import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/i18n.dart';
import '../../models/app_settings.dart';
import '../../models/task.dart';

Future<Task?> showAddTaskDialog(BuildContext context, AppLanguage language) {
  return showDialog<Task>(
    context: context,
    builder: (_) => _AddTaskDialog(language: language),
  );
}

class _AddTaskDialog extends StatefulWidget {
  const _AddTaskDialog({required this.language});

  final AppLanguage language;

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime? _deadline;
  bool _recurringEnabled = false;
  RecurrenceType _recurrenceType = RecurrenceType.weekly;
  int _weeklyDay = DateTime.now().weekday;
  int _monthlyDay = DateTime.now().day.clamp(1, 31);
  int _recurrenceReminderDays = 2;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;
    return AlertDialog(
      title: Text(tr(lang, '新建任务', 'New Task')),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: tr(lang, '任务简称', 'Task title')),
                onChanged: (_) => setState(() {}),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? tr(lang, '请输入任务名称', 'Please enter a task name') : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: tr(lang, '任务描述', 'Description')),
                minLines: 2,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _recurringEnabled,
                onChanged: (value) => setState(() => _recurringEnabled = value),
                title: Text(tr(lang, '周期任务', 'Recurring task')),
                subtitle: Text(tr(lang, '用于每周或每月重复提醒', 'Use for weekly or monthly reminders')),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _recurringEnabled ? _buildRecurringFields(lang) : _buildDeadlinePicker(lang),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr(lang, '取消', 'Cancel')),
        ),
        FilledButton(
          onPressed: _canSubmit ? _submit : null,
          child: Text(tr(lang, '保存', 'Save')),
        ),
      ],
    );
  }

  Widget _buildDeadlinePicker(AppLanguage language) {
    final formatter = DateFormat('yyyy-MM-dd', language.localeCode);
    return Row(
      key: const ValueKey('deadlinePicker'),
      children: [
        Expanded(
          child: Text(
            _deadline == null
                ? tr(language, '请选择截止日期', 'Please pick a due date')
                : formatter.format(_deadline!),
          ),
        ),
        TextButton(
          onPressed: _pickDate,
          child: Text(tr(language, '选择日期', 'Pick date')),
        ),
      ],
    );
  }

  Widget _buildRecurringFields(AppLanguage language) {
    return Column(
      key: const ValueKey('recurringFields'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<RecurrenceType>(
          initialValue: _recurrenceType,
          decoration: InputDecoration(labelText: tr(language, '周期类型', 'Recurrence type')),
          items: [
            DropdownMenuItem(value: RecurrenceType.weekly, child: Text(tr(language, '每周', 'Weekly'))),
            DropdownMenuItem(value: RecurrenceType.monthly, child: Text(tr(language, '每月', 'Monthly'))),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() => _recurrenceType = value);
          },
        ),
        const SizedBox(height: 8),
        if (_recurrenceType == RecurrenceType.weekly) _buildWeeklySelector(language) else _buildMonthlySelector(language),
        const SizedBox(height: 8),
        Text(
          tr(language, '周期任务不需要单独设置截止日期，系统会根据周期自动计算下次提醒。', 'Recurring tasks do not need a separate deadline. The app calculates the next reminder from the cycle.'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        _buildReminderSelector(language),
      ],
    );
  }

  Widget _buildWeeklySelector(AppLanguage language) {
    final labels = weekdayLabels(language);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr(language, '提醒星期', 'Day of week')),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: List.generate(labels.length, (index) {
            final weekday = index + 1;
            final selected = _weeklyDay == weekday;
            return ChoiceChip(
              label: Text(labels[index]),
              selected: selected,
              onSelected: (_) => setState(() => _weeklyDay = weekday),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMonthlySelector(AppLanguage language) {
    final items = List.generate(31, (index) => index + 1);
    return DropdownButtonFormField<int>(
      initialValue: _monthlyDay,
      decoration: InputDecoration(labelText: tr(language, '每月日期', 'Day of month')),
      items: items
          .map(
            (day) => DropdownMenuItem(
              value: day,
              child: Text(language == AppLanguage.zh ? '每月 $day 日' : 'Day $day'),
            ),
          )
          .toList(growable: false),
      onChanged: (value) {
        if (value == null) {
          return;
        }
        setState(() => _monthlyDay = value);
      },
    );
  }

  Widget _buildReminderSelector(AppLanguage language) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(tr(language, '提醒阈值 (天)', 'Reminder threshold (days)')),
      subtitle: Slider(
        value: _recurrenceReminderDays.toDouble(),
        min: 1,
        max: 7,
        divisions: 6,
        label: language == AppLanguage.zh ? '$_recurrenceReminderDays 天' : '$_recurrenceReminderDays day(s)',
        onChanged: (value) => setState(() => _recurrenceReminderDays = value.round()),
      ),
    );
  }

  bool get _canSubmit {
    if (_titleController.text.trim().isEmpty) {
      return false;
    }
    return _recurringEnabled || _deadline != null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _deadline ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      locale: Locale(widget.language == AppLanguage.zh ? 'zh' : 'en'),
    );
    if (picked != null) {
      setState(() => _deadline = DateTime(picked.year, picked.month, picked.day));
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false) || !_canSubmit) {
      return;
    }

    final task = _recurringEnabled
        ? Task.recurring(
            id: Task.freshId(_titleController.text),
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            recurrenceType: _recurrenceType,
            recurrenceValue: _recurrenceType == RecurrenceType.weekly ? _weeklyDay : _monthlyDay,
            recurrenceReminderDays: _recurrenceReminderDays,
            completed: false,
          )
        : Task.oneOff(
            id: Task.freshId(_titleController.text),
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            deadline: _deadline!,
            completed: false,
          );

    Navigator.pop(context, task);
  }
}
