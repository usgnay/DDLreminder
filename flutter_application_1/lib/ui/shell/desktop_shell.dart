import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:window_manager/window_manager.dart';

import '../../models/task.dart';
import '../../services/bootstrap.dart';
import '../../services/settings_service.dart';
import '../../services/task_service.dart';
import '../dialogs/add_task_dialog.dart';
import '../dialogs/import_dialog.dart';
import '../dialogs/settings_dialog.dart';
import '../dialogs/task_detail_dialog.dart';
import '../screens/task_board.dart';

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key, required this.container});

  final ServiceContainer container;

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  Timer? _midnightTick;
  bool _reminderShown = false;

  TaskService get tasks => widget.container.tasks;
  SettingsService get settings => widget.container.settings;

  @override
  void initState() {
    super.initState();
    _configureWindow();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowReminder());
    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    _midnightTick?.cancel();
    super.dispose();
  }

  Future<void> _configureWindow() async {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(420, 620),
      minimumSize: Size(360, 480),
      center: true,
      title: 'DDLreminder',
      backgroundColor: Colors.transparent,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  void _scheduleMidnightRefresh() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final duration = tomorrow.difference(now);
    _midnightTick?.cancel();
    _midnightTick = Timer(duration, () {
      if (!mounted) {
        return;
      }
      setState(() {});
      _scheduleMidnightRefresh();
    });
  }

  void _maybeShowReminder() {
    if (_reminderShown) {
      return;
    }
    final dueSoon = filterDueSoon(
      tasks.tasks,
      settings.value,
      DateTime.now(),
    );
    if (dueSoon.isEmpty) {
      return;
    }
    _reminderShown = true;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('即将到期的任务'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: dueSoon.length,
            itemBuilder: (context, index) {
              final task = dueSoon[index];
              final now = DateTime.now();
              final days = task.daysLeft(now);
              final dueDate = task.nextDueDate(now);
              final dateText = DateFormat('yyyy-MM-dd').format(dueDate);
              final desc = days >= 0 ? '剩余 $days 天' : '已逾期 ${days.abs()} 天';
              return ListTile(
                dense: true,
                title: Text(task.title),
                subtitle: Text('$dateText · $desc'),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('好的')),
        ],
      ),
    );
  }

  Future<void> _handleAddTask() async {
    final task = await showAddTaskDialog(context);
    if (task != null) {
      await tasks.add(task);
      _maybeShowReminder();
    }
  }

  Future<void> _handleImport() async {
    await showImportDialog(context, tasks);
    _maybeShowReminder();
  }

  Future<void> _openSettings() async {
    await showSettingsDialog(context, settings, widget.container.autostart);
  }

  Future<void> _handleDeleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除任务'),
        content: Text('确定要删除“${task.title}”吗？该操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    if (confirmed == true) {
      await tasks.remove(task.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([tasks, settings]),
      builder: (context, _) {
        final snapshot = tasks.tasks.toList(growable: false);
        return Scaffold(
          backgroundColor: settings.value.backgroundColor,
          body: SafeArea(
            child: TaskBoard(
              settings: settings.value,
              tasks: snapshot,
              onToggle: (task) => tasks.toggle(task.id),
              onOpenDetails: (task) => showTaskDetailDialog(context, task),
              onAddTask: _handleAddTask,
              onOpenSettings: _openSettings,
              onImportTasks: _handleImport,
              onDragWindow: () => windowManager.startDragging(),
              onDeleteTask: _handleDeleteTask,
            ),
          ),
        );
      },
    );
  }
}
