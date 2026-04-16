import '../models/app_settings.dart';

String tr(AppLanguage language, String zh, String en) {
  if (language != AppLanguage.zh) {
    return en;
  }

  final candidate = zh.trim();
  if (_looksBrokenLocalizedString(candidate)) {
    return en;
  }

  return candidate;
}

bool _looksBrokenLocalizedString(String value) {
  if (value.isEmpty) {
    return true;
  }

  if (value.contains('?') || value.contains('�')) {
    return true;
  }

  const mojibakeMarkers = <String>[
    '鍏',
    '鏃',
    '褰',
    '鍒',
    '纭',
    '妯',
    '棰',
    '閫',
    '闂',
    '浠',
    '绐',
    '鍛',
    '姣',
    '鏈€',
    '澶',
    '娌',
    '涓',
    '缁',
    '宸',
    '鐩',
    '鍙',
    '璇',
    '璁',
    '琛',
  ];

  return mojibakeMarkers.any(value.contains);
}

List<String> weekdayLabels(AppLanguage language) {
  if (language == AppLanguage.zh) {
    return const ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  }
  return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
}

String describeRecurringWeekly(AppLanguage language, int weekdayIndex) {
  final labels = weekdayLabels(language);
  final idx = weekdayIndex.clamp(1, 7) - 1;
  return language == AppLanguage.zh
      ? '每周 ${labels[idx]}'
      : 'Every ${labels[idx]}';
}

String describeRecurringMonthly(AppLanguage language, int day) {
  final normalized = day.clamp(1, 31);
  return language == AppLanguage.zh
      ? '每月 $normalized 日'
      : 'Day $normalized each month';
}
