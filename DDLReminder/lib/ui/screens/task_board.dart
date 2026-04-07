import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/i18n.dart';
import '../../models/app_settings.dart';
import '../../models/task.dart';
import '../widgets/recurring_task_list.dart';
import '../widgets/task_tile.dart';

class TaskBoard extends StatelessWidget {
  const TaskBoard({
    super.key,
    required this.settings,
    required this.tasks,
    required this.onToggle,
    required this.onOpenDetails,
    required this.onAddTask,
    required this.onOpenSettings,
    required this.onPreviewDate,
    required this.onImportTasks,
    required this.onDragWindow,
    required this.onDeleteTask,
    required this.onCloseApp,
  });

  final AppSettings settings;
  final List<Task> tasks;
  final void Function(Task task) onToggle;
  final void Function(Task task) onOpenDetails;
  final VoidCallback onAddTask;
  final VoidCallback onOpenSettings;
  final VoidCallback onPreviewDate;
  final VoidCallback onImportTasks;
  final VoidCallback onDragWindow;
  final void Function(Task task) onDeleteTask;
  final VoidCallback onCloseApp;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today =
        '${DateFormat.yMMMMd(settings.language.localeCode).format(now)} ${DateFormat('EEE', settings.language.localeCode).format(now)}  ${DateFormat('HH:mm').format(now)}';
    final secondaryTextColor = settings.textColor.withOpacity(.65);
    final panelSurfaceColor = settings.panelColor.withOpacity(
      settings.surfaceOpacity,
    );
    final recurringSurfaceColor = settings.panelColor.withOpacity(
      (settings.surfaceOpacity * .88).clamp(.45, 1.0),
    );
    final theme = Theme.of(context);
    final showRecurringPanel = settings.showRecurringPanel;
    final recurringTasks = showRecurringPanel
        ? tasks.where((task) => task.isRecurring).toList(growable: false)
        : const <Task>[];
    final regularTasks =
        (showRecurringPanel
              ? tasks.where((task) => !task.isRecurring).toList()
              : tasks.toList())
          ..sort((a, b) {
            if (a.completed != b.completed) {
              return a.completed ? 1 : -1;
            }
            return a.nextDueDate(now).compareTo(b.nextDueDate(now));
          });
    final usingImageBackground =
        settings.backgroundMode == BackgroundMode.image;
    final backgroundImagePath = settings.backgroundImagePath?.trim();
    final backgroundFile =
        backgroundImagePath == null || backgroundImagePath.isEmpty
        ? null
        : File(backgroundImagePath);
    final hasBackgroundImage =
        usingImageBackground &&
        backgroundFile != null &&
        backgroundFile.existsSync();

    return Stack(
      children: [
        if (!usingImageBackground)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: settings.backgroundColor.withOpacity(
                  settings.surfaceOpacity,
                ),
              ),
            ),
          ),
        if (hasBackgroundImage)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: settings.backgroundImageOpacity.clamp(.05, 1.0),
                child: Image.file(
                  backgroundFile,
                  fit: settings.backgroundImageFit == BackgroundImageFit.cover
                      ? BoxFit.cover
                      : BoxFit.contain,
                  alignment: Alignment(
                    settings.backgroundImageFocusX,
                    settings.backgroundImageFocusY,
                  ),
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        if (hasBackgroundImage && settings.backgroundImageOverlayOpacity > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: settings.backgroundImageOverlayColor.withOpacity(
                  settings.backgroundImageOverlayOpacity,
                ),
              ),
            ),
          ),
        const Positioned.fill(child: DragToMoveArea(child: SizedBox.expand())),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                slogan: settings.slogan,
                today: today,
                onDragWindow: onDragWindow,
                onOpenSettings: onOpenSettings,
                onPreviewDate: onPreviewDate,
                onCloseApp: onCloseApp,
                secondaryColor: secondaryTextColor,
                language: settings.language,
                headerTitleMaxWidth: settings.headerTitleMaxWidth,
              ),
              const SizedBox(height: 12),
              if (showRecurringPanel && recurringTasks.isNotEmpty) ...[
                RecurringTaskList(
                  tasks: recurringTasks,
                  onDelete: onDeleteTask,
                  onTap: onOpenDetails,
                  accentColor: settings.textColor,
                  surfaceColor: recurringSurfaceColor,
                  urgencyTintColor: settings.urgencyTintColor,
                  urgencyOverlayOpacity: settings.urgencyOverlayOpacity,
                  onToggle: onToggle,
                  language: settings.language,
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: panelSurfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: regularTasks.isEmpty
                      ? Center(
                          child: Text(
                            recurringTasks.isEmpty
                                ? tr(
                                    settings.language,
                                    '目前还没有任务，点击下方 + 创建新任务',
                                    'No tasks yet, tap + to create one',
                                  )
                                : tr(
                                    settings.language,
                                    '当前没有一次性任务，周期任务在上方列表',
                                    'Only recurring tasks now, see the list above',
                                  ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: secondaryTextColor,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: regularTasks.length,
                          itemBuilder: (context, index) {
                            final task = regularTasks[index];
                            final days = task.daysLeft(now);
                            return TaskTile(
                              task: task,
                              daysLeft: days,
                              urgencyTintColor: settings.urgencyTintColor,
                              urgencyOverlayOpacity:
                                  settings.urgencyOverlayOpacity,
                              onToggle: () => onToggle(task),
                              onTap: () => onOpenDetails(task),
                              onDelete: () => onDeleteTask(task),
                              language: settings.language,
                            );
                          },
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: secondaryTextColor.withOpacity(.2),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onImportTasks,
                      icon: const Icon(Icons.file_upload_outlined),
                      label: Text(
                        tr(settings.language, '导入任务', 'Import tasks'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onAddTask,
                      icon: const Icon(Icons.add),
                      label: Text(tr(settings.language, '新建任务', 'Add task')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.slogan,
    required this.today,
    required this.onOpenSettings,
    required this.onPreviewDate,
    required this.onCloseApp,
    required this.onDragWindow,
    required this.secondaryColor,
    required this.language,
    required this.headerTitleMaxWidth,
  });

  final String slogan;
  final String today;
  final VoidCallback onOpenSettings;
  final VoidCallback onPreviewDate;
  final VoidCallback onCloseApp;
  final VoidCallback onDragWindow;
  final Color secondaryColor;
  final AppLanguage language;
  final double headerTitleMaxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final titleWidth = headerTitleMaxWidth.clamp(
          120.0,
          constraints.maxWidth,
        );

        return SizedBox(
          height: 60,
          child: Stack(
            children: [
              const Positioned.fill(
                child: DragToMoveArea(child: SizedBox.expand()),
              ),
              Row(
                children: [
                  Expanded(
                    child: IgnorePointer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: titleWidth),
                            child: Text(
                              slogan,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            today,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: secondaryColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: tr(language, '日期预览', 'Preview date'),
                    onPressed: onPreviewDate,
                    icon: const Icon(Icons.event_note_outlined),
                  ),
                  IconButton(
                    tooltip: tr(language, '设置', 'Settings'),
                    onPressed: onOpenSettings,
                    icon: const Icon(Icons.settings_outlined),
                  ),
                  IconButton(
                    tooltip: tr(language, '关闭', 'Close'),
                    onPressed: onCloseApp,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
