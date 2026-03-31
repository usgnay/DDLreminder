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
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.setHasShadow(false);
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setAlwaysOnBottom(false);
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
    _midnightTick = Timer(duration, () async {
      if (!mounted) {
        return;
      }
      await tasks.refreshRecurring();
      _reminderShown = false;
      _maybeShowReminder();
      setState(() {});
      _scheduleMidnightRefresh();
    });
  }

  Future<void> _maybeShowReminder() async {
    if (_reminderShown || !mounted) {
      return;
    }

    final lang = settings.value.language;
    final dueSoon = filterDueSoon(tasks.tasks, settings.value, DateTime.now());
    if (dueSoon.isEmpty) {
      return;
    }

    _reminderShown = true;
    await widget.container.systemShell.showReminderNotification(
      title: tr(lang, '即将到期的任务', 'Upcoming deadlines'),
      body: _buildReminderSummary(dueSoon, lang),
    );

    if (!mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final size = MediaQuery.of(dialogContext).size;
        final dialogWidth = (size.width * 0.88).clamp(320.0, 420.0);
        final dialogMaxHeight = size.height * 0.55;

        return AlertDialog(
          title: Text(tr(lang, '即将到期的任务', 'Upcoming deadlines')),
          content: SizedBox(
            width: dialogWidth,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: dialogMaxHeight),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: dueSoon.map((task) {
                    final now = DateTime.now();
                    final days = task.daysLeft(now);
                    final dueDate = task.nextDueDate(now);
                    final dateText = DateFormat('yyyy-MM-dd', lang.localeCode).format(dueDate);
                    final desc = days >= 0
                        ? tr(lang, '剩余 $days 天', '$days day(s) left')
                        : tr(lang, '已逾期 ${days.abs()} 天', 'Overdue ${days.abs()} day(s)');
                    final tone = days >= 0 ? const Color(0xFF6C7B92) : const Color(0xFFB35D5D);

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: tone.withOpacity(.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: tone.withOpacity(.14)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(task.title, style: Theme.of(dialogContext).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text(
                            '$dateText · $desc',
                            style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(color: tone),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(tr(lang, '好的', 'Got it')),
            ),
          ],
        );
      },
    );
  }

  String _buildReminderSummary(List<Task> tasks, AppLanguage language) {
    final preview = tasks.take(3).map((task) => task.title).join('、');
    if (tasks.length <= 3) {
      return preview;
    }
    final remain = tasks.length - 3;
    return language == AppLanguage.zh ? '$preview 等 $remain 项' : '$preview and $remain more';
  }

  Future<void> _handleAddTask() async {
    final task = await showAddTaskDialog(context, settings.value.language);
    if (task != null) {
      await tasks.add(task);
      await _maybeShowReminder();
    }
  }

  Future<void> _handleImport() async {
    await showImportDialog(context, tasks, settings.value.language);
    await _maybeShowReminder();
  }

  Future<void> _openSettings() async {
    await showSettingsDialog(
      context,
      settings,
      widget.container.autostart,
      widget.container.fonts,
    );
  }

  Future<void> _handleDeleteTask(Task task) async {
    final lang = settings.value.language;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr(lang, '删除任务', 'Delete task')),
        content: Text(
          tr(
            lang,
            '确定要删除“${task.title}”吗？该操作不可撤销。',
            'Delete "${task.title}"? This cannot be undone.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(lang, '取消', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB35D5D)),
            child: Text(tr(lang, '删除', 'Delete')),
          ),
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
          backgroundColor: settings.value.backgroundColor.withOpacity(settings.value.surfaceOpacity),
          body: SafeArea(
            child: TaskBoard(
              settings: settings.value,
              tasks: snapshot,
              onToggle: (task) => tasks.toggle(task.id),
              onOpenDetails: (task) async {
                final updated = await showTaskDetailDialog(context, task, settings.value.language);
                if (updated != null) {
                  await tasks.update(updated);
                }
              },
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
