import 'package:flutter/material.dart';

import '../../models/task.dart';

Future<Task?> showAddTaskDialog(BuildContext context) {
  return showDialog<Task>(
    context: context,
    builder: (_) => const _AddTaskDialog(),
  );
}

class _AddTaskDialog extends StatefulWidget {
  const _AddTaskDialog();

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _deadline;
  final _formKey = GlobalKey<FormState>();
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
    return AlertDialog(
      title: const Text('新建任务'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: '任务简称'),
                onChanged: (_) => setState(() {}),
                validator: (value) => (value == null || value.trim().isEmpty) ? '请输入任务名称' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: '任务描述'),
                minLines: 2,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _recurringEnabled,
                onChanged: (value) => setState(() => _recurringEnabled = value),
                title: const Text('周期任务'),
                subtitle: const Text('用于每周或每月重复的固定提醒'),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _recurringEnabled ? _buildRecurringFields() : _buildDeadlinePicker(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(onPressed: _canSubmit ? _submit : null, child: const Text('保存')),
      ],
    );
  }

  Widget _buildDeadlinePicker() {
    return Row(
      key: const ValueKey('deadlinePicker'),
      children: [
        Expanded(
          child: Text(_deadline == null ? '请选择截止日期' : _deadline!.toString().split(' ').first),
        ),
        TextButton(
          onPressed: _pickDate,
          child: const Text('选择日期'),
        ),
      ],
    );
  }

  Widget _buildRecurringFields() {
    return Column(
      key: const ValueKey('recurringFields'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<RecurrenceType>(
          value: _recurrenceType,
          decoration: const InputDecoration(labelText: '循环类型'),
          items: const [
            DropdownMenuItem(value: RecurrenceType.weekly, child: Text('每周')),
            DropdownMenuItem(value: RecurrenceType.monthly, child: Text('每月')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _recurrenceType = value);
          },
        ),
        const SizedBox(height: 8),
        if (_recurrenceType == RecurrenceType.weekly) _buildWeeklySelector() else _buildMonthlySelector(),
        const SizedBox(height: 8),
        _buildReminderSelector(),
      ],
    );
  }

  Widget _buildWeeklySelector() {
    const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('提醒星期'),
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

  Widget _buildMonthlySelector() {
    final items = List.generate(31, (index) => index + 1);
    return DropdownButtonFormField<int>(
      value: _monthlyDay,
      decoration: const InputDecoration(labelText: '每月日期'),
      items: items.map((day) => DropdownMenuItem(value: day, child: Text('每月 $day 日'))).toList(growable: false),
      onChanged: (value) {
        if (value == null) return;
        setState(() => _monthlyDay = value);
      },
    );
  }

  Widget _buildReminderSelector() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('提醒阈值 (天)'),
      subtitle: Slider(
        value: _recurrenceReminderDays.toDouble(),
        min: 1,
        max: 3,
        divisions: 2,
        label: '${_recurrenceReminderDays} 天',
        onChanged: (value) => setState(() => _recurrenceReminderDays = value.round()),
      ),
    );
  }

  bool get _canSubmit {
    if (_titleController.text.trim().isEmpty) {
      return false;
    }
    if (_recurringEnabled) {
      return true;
    }
    return _deadline != null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _deadline ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _deadline = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false) || !_canSubmit) {
      return;
    }
    final now = DateTime.now();
    final recurrenceType = _recurringEnabled ? _recurrenceType : RecurrenceType.none;
    final recurrenceValue = _recurringEnabled
        ? (_recurrenceType == RecurrenceType.weekly ? _weeklyDay : _monthlyDay)
        : null;
    final recurrenceReminder = _recurringEnabled ? _recurrenceReminderDays : null;
    final resolvedDeadline = _recurringEnabled
        ? Task.projectNextOccurrence(recurrenceType, recurrenceValue, now)
        : _deadline!;
    final task = Task(
      id: Task.freshId(_titleController.text),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      deadline: resolvedDeadline,
      completed: false,
      recurrenceType: recurrenceType,
      recurrenceValue: recurrenceValue,
      recurrenceReminderDays: recurrenceReminder,
    );
    Navigator.pop(context, task);
  }
}
