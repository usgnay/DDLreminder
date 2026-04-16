import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/i18n.dart';
import '../../models/app_settings.dart';
import '../../models/task.dart';
import '../../providers/app_providers.dart';
import '../../services/autostart_service.dart';
import '../../services/desktop_reminder_service.dart';
import '../../services/font_service.dart';
import '../../services/settings_service.dart';
import '../../services/system_shell_service.dart';
import '../../services/task_filters.dart';
import '../../services/task_service.dart';
import '../../services/update_service.dart';
import '../dialogs/add_task_dialog.dart';
import '../dialogs/import_dialog.dart';
import '../dialogs/settings_dialog.dart';
import '../dialogs/task_detail_dialog.dart';
import '../screens/task_board.dart';

class DesktopShell extends ConsumerStatefulWidget {
  const DesktopShell({super.key});

  @override
  ConsumerState<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<DesktopShell> {
  Timer? _midnightTick;
  Timer? _minuteTick;

  TaskService get tasks => ref.read(taskServiceProvider);
  SettingsService get settings => ref.read(settingsServiceProvider);
  SystemShellService get systemShell => ref.read(systemShellServiceProvider);
  DesktopReminderService get reminderService =>
      ref.read(desktopReminderServiceProvider);
  AutostartService get autostart => ref.read(autostartServiceProvider);
  FontService get fonts => ref.read(fontServiceProvider);
  UpdateService get updates => ref.read(updateServiceProvider);

  @override
  void initState() {
    super.initState();
    _configureWindow();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowReminder());
    _scheduleMidnightRefresh();
    _scheduleMinuteRefresh();
  }

  @override
  void dispose() {
    _midnightTick?.cancel();
    _minuteTick?.cancel();
    super.dispose();
  }

  Future<void> _configureWindow() async {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(420, 620),
      minimumSize: Size(360, 480),
      center: true,
      title: 'DDLReminder',
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
    final current = settings.value;
    if (!current.showCloseConfirmDialog) {
      await _applyCloseAction(current.closeAction);
      return;
    }

    final decision = await _showCloseConfirmDialog(
      current.language,
      current.closeAction,
    );
    if (decision == null || !mounted) {
      return;
    }

    var nextSettings = current.copyWith(closeAction: decision.action);
    if (!decision.showNextTime) {
      nextSettings = nextSettings.copyWith(showCloseConfirmDialog: false);
    }
    await settings.update(nextSettings);
    await _applyCloseAction(decision.action);
  }

  Future<void> _applyCloseAction(CloseAction action) async {
    switch (action) {
      case CloseAction.minimizeToTray:
        await windowManager.hide();
        return;
      case CloseAction.exitApp:
        await systemShell.exitApplication();
        return;
    }
  }

  Future<_CloseDecision?> _showCloseConfirmDialog(
    AppLanguage language,
    CloseAction initialAction,
  ) {
    return showDialog<_CloseDecision>(
      context: context,
      builder: (dialogContext) {
        var showNextTime = true;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(tr(language, '关闭应用', 'Close app')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(
                      language,
                      '点击右上角关闭后，你希望应用如何处理？',
                      'What should happen when you close the window?',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () => Navigator.pop(
                        dialogContext,
                        _CloseDecision(
                          action: CloseAction.minimizeToTray,
                          showNextTime: showNextTime,
                        ),
                      ),
                      icon: const Icon(Icons.minimize_rounded),
                      label: Text(tr(language, '最小化到托盘', 'Minimize to tray')),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () => Navigator.pop(
                        dialogContext,
                        _CloseDecision(
                          action: CloseAction.exitApp,
                          showNextTime: showNextTime,
                        ),
                      ),
                      icon: const Icon(Icons.exit_to_app_rounded),
                      label: Text(tr(language, '直接退出', 'Exit directly')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: showNextTime,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      tr(language, '下次继续显示这个窗口', 'Show this dialog next time'),
                    ),
                    onChanged: (value) =>
                        setDialogState(() => showNextTime = value ?? true),
                  ),
                ],
              ),
              actions: [
                Text(
                  initialAction == CloseAction.minimizeToTray
                      ? tr(
                          language,
                          '当前默认：最小化到托盘',
                          'Current default: minimize to tray',
                        )
                      : tr(
                          language,
                          '当前默认：直接退出',
                          'Current default: exit directly',
                        ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(tr(language, '取消', 'Cancel')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _scheduleMidnightRefresh() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _midnightTick?.cancel();
    _midnightTick = Timer(tomorrow.difference(now), () async {
      if (!mounted) {
        return;
      }
      await tasks.refreshRecurring();
      reminderService.resetCycle();
      await _maybeShowReminder();
      setState(() {});
      _scheduleMidnightRefresh();
    });
  }

  void _scheduleMinuteRefresh() {
    final now = DateTime.now();
    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
    _minuteTick?.cancel();
    _minuteTick = Timer(nextMinute.difference(now), () {
      if (!mounted) {
        return;
      }
      setState(() {});
      _scheduleMinuteRefresh();
    });
  }

  Future<void> _maybeShowReminder() async {
    if (!mounted) {
      return;
    }

    final now = DateTime.now();
    final dueSoon = filterDueSoon(tasks.tasks, settings.value, now);
    await reminderService.maybeShowReminderDialog(
      context: context,
      settings: settings.value,
      dueSoon: dueSoon,
      now: now,
    );
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
    await showSettingsDialog(context, settings, autostart, fonts, updates);
  }

  Future<void> _previewSelectedDate() async {
    final lang = settings.value.language;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: Locale(lang == AppLanguage.zh ? 'zh' : 'en'),
    );
    if (picked == null || !mounted) {
      return;
    }

    final reference = DateTime(picked.year, picked.month, picked.day);
    final previewTasks = tasks.tasks.toList(growable: false)
      ..sort(
        (a, b) => a.nextDueDate(reference).compareTo(b.nextDueDate(reference)),
      );
    final dateFormatter = DateFormat('yyyy-MM-dd EEE', lang.localeCode);
    final timeFormatter = DateFormat('HH:mm', lang.localeCode);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(lang, '日期截止预览', 'Deadline preview')),
        content: SizedBox(
          width: 420,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogContext).size.height * .6,
            ),
            child: previewTasks.isEmpty
                ? Center(child: Text(tr(lang, '当前没有任务', 'No tasks available')))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(
                          lang,
                          '假设当前日期为 ${dateFormatter.format(reference)}',
                          'Assuming today is ${dateFormatter.format(reference)}',
                        ),
                        style: Theme.of(dialogContext).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: previewTasks.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final task = previewTasks[index];
                            final dueDate = task.nextDueDate(reference);
                            final dueText =
                                '${dateFormatter.format(dueDate)}${task.hasSpecificTime ? ' ${timeFormatter.format(dueDate)}' : ''}';
                            final days = task.daysLeft(reference);
                            final status = task.completed && !task.isRecurring
                                ? tr(lang, '已完成', 'Completed')
                                : days < 0
                                ? tr(
                                    lang,
                                    '已逾期 ${days.abs()} 天',
                                    'Overdue ${days.abs()} day(s)',
                                  )
                                : tr(lang, '剩余 $days 天', '$days day(s) left');
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(dialogContext)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: .45),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: Theme.of(
                                      dialogContext,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$dueText | $status',
                                    style: Theme.of(
                                      dialogContext,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr(lang, '关闭', 'Close')),
          ),
        ],
      ),
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
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB35D5D),
            ),
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
    final currentSettings = ref.watch(appSettingsProvider);
    final snapshot = ref.watch(taskListProvider);
    return Scaffold(
      backgroundColor: currentSettings.backgroundColor.withValues(
        alpha: currentSettings.surfaceOpacity,
      ),
      body: SafeArea(
        child: TaskBoard(
          settings: currentSettings,
          tasks: snapshot,
          onToggle: (task) => tasks.toggle(task.id),
          onOpenDetails: (task) async {
            final updated = await showTaskDetailDialog(
              context,
              task,
              currentSettings.language,
            );
            if (updated != null) {
              await tasks.update(updated);
            }
          },
          onAddTask: _handleAddTask,
          onOpenSettings: _openSettings,
          onPreviewDate: _previewSelectedDate,
          onImportTasks: _handleImport,
          onDragWindow: () => windowManager.startDragging(),
          onDeleteTask: _handleDeleteTask,
          onCloseApp: _closeApp,
        ),
      ),
    );
  }
}

class _CloseDecision {
  const _CloseDecision({required this.action, required this.showNextTime});

  final CloseAction action;
  final bool showNextTime;
}
