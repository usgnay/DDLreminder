import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/i18n.dart';
import '../../models/app_settings.dart';
import '../../models/task.dart';
import '../../providers/app_providers.dart';
import '../../services/mobile_entry_reminder_service.dart';
import '../../services/mobile_widget_sync_service.dart';
import '../../services/settings_service.dart';
import '../../services/task_filters.dart';
import '../../services/task_service.dart';
import '../dialogs/add_task_dialog.dart';
import '../dialogs/import_dialog.dart';
import '../dialogs/task_detail_dialog.dart';
import '../screens/mobile_settings_page.dart';
import '../widgets/recurring_task_list.dart';
import '../widgets/task_tile.dart';

class MobileShell extends ConsumerStatefulWidget {
  const MobileShell({super.key});

  @override
  ConsumerState<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends ConsumerState<MobileShell>
    with WidgetsBindingObserver {
  Timer? _midnightTick;
  Timer? _minuteTick;
  ProviderSubscription<List<Task>>? _taskSubscription;
  ProviderSubscription<AppSettings>? _settingsSubscription;

  TaskService get tasks => ref.read(taskServiceProvider);
  SettingsService get settings => ref.read(settingsServiceProvider);
  MobileEntryReminderService get reminderService =>
      ref.read(mobileEntryReminderServiceProvider);
  MobileWidgetSyncService get widgetSyncService =>
      ref.read(mobileWidgetSyncServiceProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _taskSubscription = ref.listenManual<List<Task>>(taskListProvider, (
      previous,
      next,
    ) {
      _syncWidgetSnapshot();
    });
    _settingsSubscription = ref.listenManual<AppSettings>(appSettingsProvider, (
      previous,
      next,
    ) {
      _syncWidgetSnapshot();
    });
    _scheduleMidnightRefresh();
    _scheduleMinuteRefresh();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowReminder());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTick?.cancel();
    _minuteTick?.cancel();
    _taskSubscription?.close();
    _settingsSubscription?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _maybeShowReminder();
    }
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

    await reminderService.maybeShowReminderDialog(
      context: context,
      settings: settings.value,
      tasks: tasks.tasks.toList(growable: false),
      now: DateTime.now(),
    );
  }

  Future<void> _handleAddTask() async {
    final task = await showAddTaskDialog(context, settings.value.language);
    if (task != null) {
      await tasks.add(task);
      await _maybeShowReminder();
    }
  }

  Future<void> _handleOpenTask(Task task) async {
    final updated = await showTaskDetailDialog(
      context,
      task,
      settings.value.language,
    );
    if (updated != null) {
      await tasks.update(updated);
      await _maybeShowReminder();
    }
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
            child: Text(tr(lang, '删除', 'Delete')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await tasks.remove(task.id);
    }
  }

  Future<void> _openSettings() {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MobileSettingsPage(
          settings: settings,
          onPreviewDate: _previewSelectedDate,
          onImportTasks: _handleImport,
        ),
      ),
    );
  }

  Future<void> _handleImport() async {
    await showImportDialog(context, tasks, settings.value.language);
    await _maybeShowReminder();
  }

  Future<void> _syncWidgetSnapshot() async {
    if (!mounted) {
      return;
    }

    await widgetSyncService.syncIfNeeded(
      tasks: tasks.tasks.toList(growable: false),
      settings: settings.value,
      now: DateTime.now(),
    );
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
              maxHeight: MediaQuery.of(dialogContext).size.height * .65,
            ),
            child: previewTasks.isEmpty
                ? Center(child: Text(tr(lang, '当前没有任务', 'No tasks available')))
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: previewTasks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
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
                          : tr(lang, '还剩 $days 天', '$days day(s) left');
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(dialogContext)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: .5),
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
                              '$dueText  |  $status',
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

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(appSettingsProvider);
    final taskItems = ref.watch(taskListProvider);
    final recurringTasks = ref.watch(recurringTasksProvider);
    final oneOffTasks = ref.watch(oneOffTasksProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final language = current.language;
    final now = DateTime.now();
    final allTasks = taskItems.toList(growable: false);
    final dueSoonCount = filterDueSoon(allTasks, current, now).length;
    final dateLabel = DateFormat(
      'yyyy-MM-dd EEEE',
      language.localeCode,
    ).format(now);

    return Stack(
      children: [
        Positioned.fill(child: _buildBackground(current, isDarkMode)),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            titleSpacing: 16,
            backgroundColor: _resolveAppBarColor(current, isDarkMode),
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DDLReminder',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(dateLabel, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            actions: [
              IconButton(
                onPressed: _handleImport,
                icon: const Icon(Icons.file_upload_outlined),
                tooltip: tr(language, '导入任务', 'Import tasks'),
              ),
              IconButton(
                onPressed: _openSettings,
                icon: const Icon(Icons.tune_rounded),
                tooltip: tr(language, '设置', 'Settings'),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _handleAddTask,
            icon: const Icon(Icons.add),
            label: Text(tr(language, '添加任务', 'Add task')),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              children: [
                _SummaryCard(
                  language: language,
                  slogan: current.slogan,
                  dueSoonCount: dueSoonCount,
                  oneOffCount: oneOffTasks.length,
                  recurringCount: recurringTasks.length,
                ),
                if (current.showRecurringPanel &&
                    recurringTasks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  RecurringTaskList(
                    tasks: recurringTasks,
                    onDelete: _handleDeleteTask,
                    onTap: _handleOpenTask,
                    accentColor: current.textColor,
                    surfaceColor: current.panelColor.withValues(alpha: .95),
                    urgencyTintColor: current.urgencyTintColor,
                    urgencyOverlayOpacity: current.urgencyOverlayOpacity,
                    onToggle: (task) => tasks.toggle(task.id),
                    language: language,
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  tr(language, '任务列表', 'Tasks'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (oneOffTasks.isEmpty)
                  _EmptyState(language: language)
                else
                  ...oneOffTasks.map((task) {
                    final daysLeft = task.daysLeft(now);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TaskTile(
                        task: task,
                        daysLeft: daysLeft,
                        urgencyTintColor: current.urgencyTintColor,
                        urgencyOverlayOpacity: current.urgencyOverlayOpacity,
                        onToggle: () => tasks.toggle(task.id),
                        onTap: () => _handleOpenTask(task),
                        onDelete: () => _handleDeleteTask(task),
                        language: language,
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackground(AppSettings settings, bool isDarkMode) {
    final overlay = _buildAdaptiveOverlay(settings, isDarkMode);
    if (settings.backgroundMode == BackgroundMode.image &&
        (settings.backgroundImagePath?.trim().isNotEmpty ?? false)) {
      final imageFile = File(settings.backgroundImagePath!.trim());
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            imageFile,
            fit: settings.backgroundImageFit == BackgroundImageFit.cover
                ? BoxFit.cover
                : BoxFit.contain,
            alignment: Alignment(
              settings.backgroundImageFocusX,
              settings.backgroundImageFocusY,
            ),
            errorBuilder: (_, _, _) =>
                ColoredBox(color: settings.backgroundColor),
          ),
          Container(
            color: settings.backgroundImageOverlayColor.withValues(
              alpha: settings.backgroundImageOverlayOpacity,
            ),
          ),
          if (overlay != null) overlay,
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: settings.backgroundColor),
        if (isDarkMode) Container(color: Colors.black.withValues(alpha: .18)),
        if (overlay != null) overlay,
      ],
    );
  }

  Widget? _buildAdaptiveOverlay(AppSettings settings, bool isDarkMode) {
    if (!settings.mobileFollowSystemOverlay ||
        settings.mobileSystemOverlayOpacity <= 0) {
      return null;
    }
    return Container(
      color: (isDarkMode ? Colors.black : Colors.white).withValues(
        alpha: settings.mobileSystemOverlayOpacity,
      ),
    );
  }

  Color _resolveAppBarColor(AppSettings settings, bool isDarkMode) {
    final base = settings.mobileAppBarColor;
    if (!settings.mobileFollowSystemOverlay ||
        settings.mobileSystemOverlayOpacity <= 0) {
      return base;
    }
    final overlay = (isDarkMode ? Colors.black : Colors.white).withValues(
      alpha: settings.mobileSystemOverlayOpacity * .8,
    );
    return Color.alphaBlend(overlay, base);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.language,
    required this.slogan,
    required this.dueSoonCount,
    required this.oneOffCount,
    required this.recurringCount,
  });

  final AppLanguage language;
  final String slogan;
  final int dueSoonCount;
  final int oneOffCount;
  final int recurringCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: .12),
            scheme.secondary.withValues(alpha: .18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            slogan,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              language,
              '先处理最临近的截止事项，再安排后续节奏。',
              'Handle the nearest deadlines first, then plan the rest.',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                label: tr(
                  language,
                  '即将到期 $dueSoonCount',
                  '$dueSoonCount due soon',
                ),
              ),
              _InfoChip(
                label: tr(
                  language,
                  '普通任务 $oneOffCount',
                  '$oneOffCount one-off',
                ),
              ),
              _InfoChip(
                label: tr(
                  language,
                  '周期任务 $recurringCount',
                  '$recurringCount recurring',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.language});

  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 36),
          const SizedBox(height: 10),
          Text(tr(language, '还没有普通任务', 'No one-off tasks yet')),
          const SizedBox(height: 4),
          Text(
            tr(
              language,
              '点击右下角按钮即可添加你的第一项任务。',
              'Tap the button in the lower-right corner to add your first task.',
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
