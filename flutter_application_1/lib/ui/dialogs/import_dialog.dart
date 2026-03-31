import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/i18n.dart';
import '../../models/app_settings.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';

Future<void> showImportDialog(BuildContext context, TaskService tasks, AppLanguage language) async {
  final controller = TextEditingController(text: _sampleJson);
  await showDialog<void>(
    context: context,
    builder: (_) => _ImportDialog(tasks: tasks, controller: controller, language: language),
  );
  controller.dispose();
}

class _ImportDialog extends StatefulWidget {
  const _ImportDialog({required this.tasks, required this.controller, required this.language});

  final TaskService tasks;
  final TextEditingController controller;
  final AppLanguage language;

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  String? _status;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr(widget.language, '导入任务', 'Import tasks')),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(tr(widget.language, 'JSON 格式示例 (只读)：', 'JSON example (read-only):')),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: widget.controller,
              readOnly: true,
              maxLines: 6,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickFile,
              icon: const Icon(Icons.folder_open),
              label: Text(tr(widget.language, '选择 JSON 文件', 'Choose JSON file')),
            ),
            if (_status != null) ...[
              const SizedBox(height: 8),
              Text(_status!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.deepOrange)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(tr(widget.language, '关闭', 'Close')),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    setState(() {
      _busy = true;
      _status = tr(widget.language, '正在解析...', 'Parsing...');
    });
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null || result.files.single.path == null) {
        setState(() {
          _status = tr(widget.language, '已取消', 'Cancelled');
          _busy = false;
        });
        return;
      }
      final path = result.files.single.path!;
      final payload = await File(path).readAsString();
      final parsed = jsonDecode(payload);
      if (parsed is! List) {
        setState(() {
          _status = tr(widget.language, '格式错误：根节点必须是数组', 'Format error: root node must be an array');
          _busy = false;
        });
        return;
      }
      final buffer = <Task>[];
      final issues = <String>[];
      for (var i = 0; i < parsed.length; i++) {
        final row = parsed[i];
        if (row is! Map) {
          issues.add(widget.language == AppLanguage.zh ? '第 ${i + 1} 行不是对象' : 'Row ${i + 1} is not an object');
          continue;
        }
        final node = Map<String, dynamic>.from(row);
        final title = (node['title'] as String?)?.trim();
        final deadlineRaw = node['deadline'] as String?;
        final description = (node['description'] as String?)?.trim() ?? '';
        final completed = node['completed'] as bool? ?? false;
        final recurrenceType = _parseRecurrence(node['recurrenceType'] as String?);
        final recurrenceValue = node['recurrenceValue'] as int?;
        final recurrenceReminderDays = node['recurrenceReminderDays'] as int?;
        if (title == null || title.isEmpty) {
          issues.add(widget.language == AppLanguage.zh ? '第 ${i + 1} 行缺少 title' : 'Row ${i + 1} missing title');
          continue;
        }
        DateTime? deadline;
        if (recurrenceType == RecurrenceType.none) {
          deadline = DateTime.tryParse(deadlineRaw ?? '');
          if (deadline == null) {
            issues.add(widget.language == AppLanguage.zh ? '第 ${i + 1} 行 deadline 无法解析' : 'Row ${i + 1} has invalid deadline');
            continue;
          }
        } else {
          if (recurrenceValue == null) {
            issues.add(widget.language == AppLanguage.zh ? '第 ${i + 1} 行缺少 recurrenceValue' : 'Row ${i + 1} missing recurrenceValue');
            continue;
          }
          final now = DateTime.now();
          deadline = DateTime(now.year, now.month, now.day);
        }
        final taskId = node['id'] as String? ?? Task.freshId(title);
        final normalizedDeadline = DateTime(deadline.year, deadline.month, deadline.day);
        buffer.add(
          recurrenceType == RecurrenceType.none
              ? Task.oneOff(
                  id: taskId,
                  title: title,
                  description: description,
                  deadline: normalizedDeadline,
                  completed: completed,
                )
              : Task.recurring(
                  id: taskId,
                  title: title,
                  description: description,
                  recurrenceType: recurrenceType,
                  recurrenceValue: recurrenceValue!,
                  recurrenceReminderDays: recurrenceReminderDays ?? 2,
                  completed: completed,
                ),
        );
      }
      if (buffer.isEmpty) {
        setState(() {
          _status = widget.language == AppLanguage.zh
              ? '未导入任何任务：${issues.join('，')}'
              : 'No tasks imported: ${issues.join('; ')}';
          _busy = false;
        });
        return;
      }
      await widget.tasks.importMany(buffer);
      setState(() {
        _status = widget.language == AppLanguage.zh
            ? '成功导入 ${buffer.length} 条任务${issues.isEmpty ? '' : '，有警告：${issues.join('；')}'}'
            : 'Imported ${buffer.length} task(s)${issues.isEmpty ? '' : ' with warnings: ${issues.join('; ')}'}';
        _busy = false;
      });
    } catch (error) {
      setState(() {
        _status = widget.language == AppLanguage.zh ? '导入失败：$error' : 'Import failed: $error';
        _busy = false;
      });
    }
  }
}

RecurrenceType _parseRecurrence(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'weekly':
      return RecurrenceType.weekly;
    case 'monthly':
      return RecurrenceType.monthly;
    default:
      return RecurrenceType.none;
  }
}

const _sampleJson = '''[
  {
    "title": "项目报告",
    "deadline": "2026-04-01",
    "description": "完成技术报告并提交",
    "completed": false
  },
  {
    "title": "周会复盘",
    "recurrenceType": "weekly",
    "recurrenceValue": 1,
    "recurrenceReminderDays": 1,
    "description": "每周一上午同步重点"
  }
]''';
