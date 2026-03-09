import '../models/app_settings.dart';

String tr(AppLanguage language, String zh, String en) => language == AppLanguage.zh ? zh : en;

List<String> weekdayLabels(AppLanguage language) {
  if (language == AppLanguage.zh) {
    return const ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  }
  return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
}

String describeRecurringWeekly(AppLanguage language, int weekdayIndex) {
  final labels = weekdayLabels(language);
  final idx = weekdayIndex.clamp(1, 7) - 1;
  return language == AppLanguage.zh ? '每周 ${labels[idx]}' : 'Every ${labels[idx]}';
}

String describeRecurringMonthly(AppLanguage language, int day) {
  final normalized = day.clamp(1, 31);
  return language == AppLanguage.zh ? '每月 $normalized 日' : 'Day $normalized each month';
}
