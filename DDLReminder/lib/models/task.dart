import 'dart:convert';
import 'dart:math';

enum RecurrenceType { none, weekly, monthly }

class Task {
  static final Random _random = Random();

  final String id;
  final String title;
  final String description;
  final DateTime? deadline;
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

  factory Task.oneOff({
    required String id,
    required String title,
    required String description,
    required DateTime deadline,
    required bool completed,
  }) {
    return Task(
      id: id,
      title: title,
      description: description,
      deadline: _dateOnly(deadline),
      completed: completed,
    );
  }

  factory Task.recurring({
    required String id,
    required String title,
    required String description,
    required RecurrenceType recurrenceType,
    required int recurrenceValue,
    required int recurrenceReminderDays,
    required bool completed,
  }) {
    return Task(
      id: id,
      title: title,
      description: description,
      deadline: null,
      completed: completed,
      recurrenceType: recurrenceType,
      recurrenceValue: recurrenceValue,
      recurrenceReminderDays: recurrenceReminderDays,
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    bool clearDeadline = false,
    bool? completed,
    RecurrenceType? recurrenceType,
    int? recurrenceValue,
    int? recurrenceReminderDays,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      completed: completed ?? this.completed,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceValue: recurrenceValue ?? this.recurrenceValue,
      recurrenceReminderDays: recurrenceReminderDays ?? this.recurrenceReminderDays,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final recurrenceType = _parseRecurrence(json['recurrenceType'] as String?);
    final parsedDeadline = DateTime.tryParse(json['deadline'] as String? ?? '');
    final normalizedDeadline = parsedDeadline == null ? null : _dateOnly(parsedDeadline);

    return Task(
      id: json['id'] as String? ?? _makeId(json['title'] as String? ?? ''),
      title: json['title'] as String? ?? '未命名任务',
      description: json['description'] as String? ?? '',
      deadline: recurrenceType == RecurrenceType.none ? normalizedDeadline ?? _dateOnly(DateTime.now()) : null,
      completed: json['completed'] as bool? ?? false,
      recurrenceType: recurrenceType,
      recurrenceValue: json['recurrenceValue'] as int?,
      recurrenceReminderDays: json['recurrenceReminderDays'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'completed': completed,
      'recurrenceType': recurrenceType.name,
      'recurrenceValue': recurrenceValue,
      'recurrenceReminderDays': recurrenceReminderDays,
    };
  }

  bool get isRecurring => recurrenceType != RecurrenceType.none;

  DateTime? get oneOffDeadline => isRecurring ? null : deadline;

  int daysLeft(DateTime today) {
    final dateOnlyDeadline = nextDueDate(today);
    final dateOnlyToday = _dateOnly(today);
    return dateOnlyDeadline.difference(dateOnlyToday).inDays;
  }

  bool get isOverdue {
    final today = DateTime.now();
    return !isRecurring && daysLeft(today) < 0 && !completed;
  }

  DateTime nextDueDate(DateTime reference) {
    if (!isRecurring) {
      return deadline ?? _dateOnly(reference);
    }
    final sanitizedToday = _dateOnly(reference);
    return projectNextOccurrence(recurrenceType, recurrenceValue, sanitizedToday);
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
    final sanitizedFrom = _dateOnly(from);
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
        return sanitizedFrom;
    }
  }

  static DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

  static int _daysInMonth(int year, int month) {
    final firstDayNextMonth = month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    return firstDayNextMonth.subtract(const Duration(days: 1)).day;
  }
}
