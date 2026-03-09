import 'dart:convert';
import 'dart:math';

enum RecurrenceType { none, weekly, monthly }

class Task {
  static final Random _random = Random();

  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final bool completed;
  final RecurrenceType recurrenceType;
  final int? recurrenceValue;
  final int? recurrenceReminderDays;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.completed,
    this.recurrenceType = RecurrenceType.none,
    this.recurrenceValue,
    this.recurrenceReminderDays,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    bool? completed,
    RecurrenceType? recurrenceType,
    int? recurrenceValue,
    int? recurrenceReminderDays,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      completed: completed ?? this.completed,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceValue: recurrenceValue ?? this.recurrenceValue,
      recurrenceReminderDays: recurrenceReminderDays ?? this.recurrenceReminderDays,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final parsedDeadline = DateTime.tryParse(json['deadline'] as String? ?? '') ?? DateTime.now();
    final sanitizedDeadline = DateTime(parsedDeadline.year, parsedDeadline.month, parsedDeadline.day);
    return Task(
      id: json['id'] as String? ?? _makeId(json['title'] as String? ?? ''),
      title: json['title'] as String? ?? '未命名任务',
      description: json['description'] as String? ?? '',
      deadline: sanitizedDeadline,
      completed: json['completed'] as bool? ?? false,
      recurrenceType: _parseRecurrence(json['recurrenceType'] as String?),
      recurrenceValue: json['recurrenceValue'] as int?,
      recurrenceReminderDays: json['recurrenceReminderDays'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'completed': completed,
      'recurrenceType': recurrenceType.name,
      'recurrenceValue': recurrenceValue,
      'recurrenceReminderDays': recurrenceReminderDays,
    };
  }

  int daysLeft(DateTime today) {
    final dateOnlyDeadline = _effectiveDeadline(today);
    final dateOnlyToday = DateTime(today.year, today.month, today.day);
    return dateOnlyDeadline.difference(dateOnlyToday).inDays;
  }

  bool get isOverdue {
    final today = DateTime.now();
    return daysLeft(today) < 0 && !completed;
  }

  bool get isRecurring => recurrenceType != RecurrenceType.none;

  DateTime nextDueDate(DateTime reference) => _effectiveDeadline(reference);

  DateTime _effectiveDeadline(DateTime today) {
    final sanitizedToday = DateTime(today.year, today.month, today.day);
    if (!isRecurring) {
      return DateTime(deadline.year, deadline.month, deadline.day);
    }
    return Task.projectNextOccurrence(recurrenceType, recurrenceValue, sanitizedToday);
  }

  static String freshId([String seed = '']) {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final randomBits = _random.nextInt(1 << 32);
    final seedHash = seed.trim().isEmpty ? '' : '-${base64Url.encode(utf8.encode(seed.trim())).replaceAll('=', '')}';
    return '$stamp-${randomBits.toRadixString(16).padLeft(8, '0')}$seedHash';
  }

  static String _makeId(String seed) => freshId(seed);

  static RecurrenceType _parseRecurrence(String? raw) {
    switch (raw) {
      case 'weekly':
        return RecurrenceType.weekly;
      case 'monthly':
        return RecurrenceType.monthly;
      default:
        return RecurrenceType.none;
    }
  }

  static DateTime projectNextOccurrence(RecurrenceType type, int? recurrenceValue, DateTime from) {
    final sanitizedFrom = DateTime(from.year, from.month, from.day);
    switch (type) {
      case RecurrenceType.weekly:
        final targetWeekday = (recurrenceValue ?? sanitizedFrom.weekday).clamp(1, 7);
        var date = sanitizedFrom;
        while (date.weekday != targetWeekday) {
          date = date.add(const Duration(days: 1));
        }
        return date;
      case RecurrenceType.monthly:
        final desiredDay = (recurrenceValue ?? sanitizedFrom.day).clamp(1, 31);
        var year = sanitizedFrom.year;
        var month = sanitizedFrom.month;
        if (sanitizedFrom.day > desiredDay) {
          month += 1;
          if (month > 12) {
            month = 1;
            year += 1;
          }
        }
        final lastDay = _daysInMonth(year, month);
        final actualDay = desiredDay > lastDay ? lastDay : desiredDay;
        return DateTime(year, month, actualDay);
      case RecurrenceType.none:
        return DateTime(from.year, from.month, from.day);
    }
  }

  static int _daysInMonth(int year, int month) {
    final firstDayNextMonth = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    return firstDayNextMonth.subtract(const Duration(days: 1)).day;
  }
}
