import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/i18n.dart';
import '../../models/app_settings.dart';
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
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      // Keep the widget acting like a sticky note: frameless and anchored beneath other windows.
      await windowManager.setHasShadow(false);
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setAlwaysOnBottom(true);
      await windowManager.show();
      await windowManager.focus();
    });
  }

  Future<void> _closeApp() async {
    await windowManager.close();
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
    final lang = settings.value.language;
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
        title: Text(tr(lang, '即将到期的任务', 'Upcoming deadlines')),
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
              final dateText = DateFormat('yyyy-MM-dd', lang.localeCode).format(dueDate);
              final desc = days >= 0
                  ? tr(lang, '剩余 $days 天', '$days day(s) left')
                  : tr(lang, '已逾期 ${days.abs()} 天', 'Overdue ${days.abs()} day(s)');
              return ListTile(
                dense: true,
                title: Text(task.title),
                subtitle: Text('$dateText · $desc'),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr(lang, '好的', 'Got it'))),
        ],
      ),
    );
  }

  Future<void> _handleAddTask() async {
    final task = await showAddTaskDialog(context, settings.value.language);
    if (task != null) {
      await tasks.add(task);
      _maybeShowReminder();
    }
  }

  Future<void> _handleImport() async {
    await showImportDialog(context, tasks, settings.value.language);
    _maybeShowReminder();
  }

  Future<void> _openSettings() async {
    await showSettingsDialog(context, settings, widget.container.autostart, widget.container.fonts);
  }

  Future<void> _handleDeleteTask(Task task) async {
    final lang = settings.value.language;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr(lang, '删除任务', 'Delete task')),
        content: Text(tr(lang, '确定要删除“${task.title}”吗？该操作不可撤销。', 'Delete “${task.title}”? This cannot be undone.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr(lang, '取消', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(tr(lang, '删除', 'Delete'))),
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
              onOpenDetails: (task) => showTaskDetailDialog(context, task, settings.value.language),
              onAddTask: _handleAddTask,
              onOpenSettings: _openSettings,
              onImportTasks: _handleImport,
              onDragWindow: () => windowManager.startDragging(),
              onDeleteTask: _handleDeleteTask,
              onCloseApp: _closeApp,
            ),
          ),
        );
      },
    );
  }
}
