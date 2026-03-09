import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    required this.onImportTasks,
    required this.onDragWindow,
    required this.onDeleteTask,
  });

  final AppSettings settings;
  final List<Task> tasks;
  final void Function(Task task) onToggle;
  final void Function(Task task) onOpenDetails;
  final VoidCallback onAddTask;
  final VoidCallback onOpenSettings;
  final VoidCallback onImportTasks;
  final VoidCallback onDragWindow;
  final void Function(Task task) onDeleteTask;

  @override
  Widget build(BuildContext context) {
    final today = DateFormat.yMMMMd('zh_CN').format(DateTime.now());
    final secondaryTextColor = settings.textColor.withOpacity(.65);
    final theme = Theme.of(context);
    final showRecurringPanel = settings.showRecurringPanel;
    final recurringTasks = showRecurringPanel
      ? tasks.where((task) => task.isRecurring).toList(growable: false)
      : const <Task>[];
    final regularTasks = showRecurringPanel
      ? tasks.where((task) => !task.isRecurring).toList(growable: false)
      : tasks;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            slogan: settings.slogan,
            today: today,
            onDragWindow: onDragWindow,
            onOpenSettings: onOpenSettings,
            secondaryColor: secondaryTextColor,
          ),
          const SizedBox(height: 12),
          if (showRecurringPanel && recurringTasks.isNotEmpty) ...[
            RecurringTaskList(
              tasks: recurringTasks,
              onDelete: onDeleteTask,
              onTap: onOpenDetails,
              accentColor: settings.textColor,
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: settings.panelColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8))],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: regularTasks.isEmpty
                  ? Center(
                      child: Text(
                        recurringTasks.isEmpty
                            ? '目前还没有任务，点击下方的 + 创建新任务'
                            : '当下没有一次性任务，周期任务在上方列表',
                        style: theme.textTheme.bodyMedium?.copyWith(color: secondaryTextColor),
                      ),
                    )
                  : ListView.separated(
                      itemCount: regularTasks.length,
                      itemBuilder: (context, index) {
                        final task = regularTasks[index];
                        final days = task.daysLeft(DateTime.now());
                        return TaskTile(
                          task: task,
                          daysLeft: days,
                          onToggle: () => onToggle(task),
                          onTap: () => onOpenDetails(task),
                          onDelete: () => onDeleteTask(task),
                        );
                      },
                      separatorBuilder: (_, __) => Divider(height: 1, color: secondaryTextColor.withOpacity(.2)),
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
                  label: const Text('导入任务'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAddTask,
                  icon: const Icon(Icons.add),
                  label: const Text('新建任务'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.slogan,
    required this.today,
    required this.onOpenSettings,
    required this.onDragWindow,
    required this.secondaryColor,
  });

  final String slogan;
  final String today;
  final VoidCallback onOpenSettings;
  final VoidCallback onDragWindow;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => onDragWindow(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slogan, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(today, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: secondaryColor)),
              ],
            ),
          ),
          IconButton(
            tooltip: '设置',
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }
}
