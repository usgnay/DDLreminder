import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/i18n.dart';
import '../models/app_settings.dart';
import '../models/task.dart';
import 'system_shell_service.dart';

class DesktopReminderService {
  DesktopReminderService(this._systemShell);

  final SystemShellService _systemShell;
  bool _reminderShown = false;

  void resetCycle() {
    _reminderShown = false;
  }

  Future<void> maybeShowReminderDialog({
    required BuildContext context,
    required AppSettings settings,
    required List<Task> dueSoon,
    required DateTime now,
  }) async {
    if (_reminderShown || dueSoon.isEmpty) {
      return;
    }

    final language = settings.language;
    _reminderShown = true;
    await _systemShell.showReminderNotification(
      title: tr(language, '即将到期的任务', 'Upcoming deadlines'),
      body: buildReminderSummary(dueSoon, language),
    );

    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final size = MediaQuery.of(dialogContext).size;
        final dialogWidth = (size.width * 0.88).clamp(320.0, 420.0);
        final dialogMaxHeight = size.height * 0.55;

        return AlertDialog(
          title: Text(tr(language, '即将到期的任务', 'Upcoming deadlines')),
          content: SizedBox(
            width: dialogWidth,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: dialogMaxHeight),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: dueSoon.map((task) {
                    final days = task.daysLeft(now);
                    final dueDate = task.nextDueDate(now);
                    final dateText = DateFormat(
                      'yyyy-MM-dd',
                      language.localeCode,
                    ).format(dueDate);
                    final description = days >= 0
                        ? tr(language, '剩余 $days 天', '$days day(s) left')
                        : tr(
                            language,
                            '已逾期 ${days.abs()} 天',
                            'Overdue ${days.abs()} day(s)',
                          );
                    final tone = days >= 0
                        ? const Color(0xFF6C7B92)
                        : const Color(0xFFB35D5D);

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: tone.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: tone.withValues(alpha: .14)),
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
                          const SizedBox(height: 6),
                          Text(
                            '$dateText | $description',
                            style: Theme.of(
                              dialogContext,
                            ).textTheme.bodySmall?.copyWith(color: tone),
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
              child: Text(tr(language, '好的', 'Got it')),
            ),
          ],
        );
      },
    );
  }

  String buildReminderSummary(List<Task> tasks, AppLanguage language) {
    final preview = tasks.take(3).map((task) => task.title).join('、');
    if (tasks.length <= 3) {
      return preview;
    }

    final remain = tasks.length - 3;
    return language == AppLanguage.zh
        ? '$preview 等 $remain 项'
        : '$preview and $remain more';
  }
}
