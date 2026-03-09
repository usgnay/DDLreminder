import 'package:flutter/material.dart';

enum AppLanguage { zh, en }

extension AppLanguageX on AppLanguage {
  String get localeCode => this == AppLanguage.zh ? 'zh_CN' : 'en_US';
  String get displayName => this == AppLanguage.zh ? '中文' : 'English';
  String get storageKey => this == AppLanguage.zh ? 'zh' : 'en';

  static AppLanguage parse(String? raw) {
    if (raw == 'en') {
      return AppLanguage.en;
    }
    return AppLanguage.zh;
  }
}

class AppSettings {
  final int reminderThresholdDays;
  final bool autoLaunch;
  final int textColorValue;
  final int backgroundColorValue;
  final int panelColorValue;
  final String slogan;
  final bool showRecurringPanel;
  final int weeklyReminderDays;
  final int monthlyReminderDays;
  final AppLanguage language;

  const AppSettings({
    required this.reminderThresholdDays,
    required this.autoLaunch,
    required this.textColorValue,
    required this.backgroundColorValue,
    required this.panelColorValue,
    required this.slogan,
    required this.showRecurringPanel,
    required this.weeklyReminderDays,
    required this.monthlyReminderDays,
    required this.language,
  });

  factory AppSettings.defaults() {
    return AppSettings(
      reminderThresholdDays: 3,
      autoLaunch: false,
      textColorValue: Colors.black.value,
      backgroundColorValue: const Color(0xFFF5F5F7).value,
      panelColorValue: Colors.white.value,
      slogan: '专注每一天',
      showRecurringPanel: true,
      weeklyReminderDays: 2,
      monthlyReminderDays: 3,
      language: AppLanguage.zh,
    );
  }

  AppSettings copyWith({
    int? reminderThresholdDays,
    bool? autoLaunch,
    int? textColorValue,
    int? backgroundColorValue,
    int? panelColorValue,
    String? slogan,
    bool? showRecurringPanel,
    int? weeklyReminderDays,
    int? monthlyReminderDays,
    AppLanguage? language,
  }) {
    return AppSettings(
      reminderThresholdDays: reminderThresholdDays ?? this.reminderThresholdDays,
      autoLaunch: autoLaunch ?? this.autoLaunch,
      textColorValue: textColorValue ?? this.textColorValue,
      backgroundColorValue: backgroundColorValue ?? this.backgroundColorValue,
      panelColorValue: panelColorValue ?? this.panelColorValue,
      slogan: slogan ?? this.slogan,
      showRecurringPanel: showRecurringPanel ?? this.showRecurringPanel,
      weeklyReminderDays: weeklyReminderDays ?? this.weeklyReminderDays,
      monthlyReminderDays: monthlyReminderDays ?? this.monthlyReminderDays,
      language: language ?? this.language,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      reminderThresholdDays: json['reminderThresholdDays'] as int? ?? 3,
      autoLaunch: json['autoLaunch'] as bool? ?? false,
      textColorValue: json['textColorValue'] as int? ?? Colors.black.value,
      backgroundColorValue: json['backgroundColorValue'] as int? ?? const Color(0xFFF5F5F7).value,
      panelColorValue: json['panelColorValue'] as int? ?? Colors.white.value,
      slogan: json['slogan'] as String? ?? '专注每一天',
      showRecurringPanel: json['showRecurringPanel'] as bool? ?? true,
      weeklyReminderDays: json['weeklyReminderDays'] as int? ?? 2,
      monthlyReminderDays: json['monthlyReminderDays'] as int? ?? 3,
      language: AppLanguageX.parse(json['language'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reminderThresholdDays': reminderThresholdDays,
      'autoLaunch': autoLaunch,
      'textColorValue': textColorValue,
      'backgroundColorValue': backgroundColorValue,
      'panelColorValue': panelColorValue,
      'slogan': slogan,
      'showRecurringPanel': showRecurringPanel,
      'weeklyReminderDays': weeklyReminderDays,
      'monthlyReminderDays': monthlyReminderDays,
      'language': language.storageKey,
    };
  }

  Color get textColor => Color(textColorValue);
  Color get backgroundColor => Color(backgroundColorValue);
  Color get panelColor => Color(panelColorValue);
}
