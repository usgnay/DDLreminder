import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/i18n.dart';
import '../models/app_settings.dart';
import '../models/task.dart';

class MobileWidgetService {
  static const MethodChannel _channel = MethodChannel(
    'ddlreminder/mobile_widget',
  );

  Future<void> syncTasks({
    required List<Task> tasks,
    required AppSettings settings,
    DateTime? now,
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }

    final language = settings.language;
    final currentTime = now ?? DateTime.now();
    final activeTasks =
        tasks
            .where((task) => task.isRecurring || !task.completed)
            .toList(growable: false)
          ..sort(
            (a, b) => a
                .nextDueDate(currentTime)
                .compareTo(b.nextDueDate(currentTime)),
          );
    final topTasks = activeTasks.take(2).toList(growable: false);
    final formatter = DateFormat('MM-dd EEE', language.localeCode);
    final timeFormatter = DateFormat('HH:mm', language.localeCode);

    final payload = topTasks
        .map((task) {
          final due = task.nextDueDate(currentTime);
          final dueText = formatter.format(due);
          final subtitle = task.hasSpecificTime
              ? '$dueText ${timeFormatter.format(due)}'
              : dueText;
          return {'title': task.title, 'subtitle': subtitle};
        })
        .toList(growable: false);

    try {
      await _channel.invokeMethod<void>('syncTasks', {
        'headerTitle': tr(language, 'DDL 提醒', 'DDL Reminder'),
        'slogan': settings.slogan,
        'emptyTitle': tr(language, '暂无任务', 'No tasks'),
        'emptySubtitle': tr(
          language,
          '添加任务后，这里会显示最近需要关注的两项。',
          'Add tasks and the two most urgent items will appear here.',
        ),
        'tasks': payload,
      });
    } catch (_) {
      // Widget sync is best-effort on Android only.
    }
  }
}
