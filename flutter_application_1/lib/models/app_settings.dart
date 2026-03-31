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

enum AppFontFamily { system, notoSans, inter, custom }

extension AppFontFamilyX on AppFontFamily {
  String get storageKey {
    switch (this) {
      case AppFontFamily.notoSans:
        return 'notoSans';
      case AppFontFamily.inter:
        return 'inter';
      case AppFontFamily.custom:
        return 'custom';
      case AppFontFamily.system:
        return 'system';
    }
  }

  String displayName(AppLanguage language) {
    final zh = language == AppLanguage.zh;
    switch (this) {
      case AppFontFamily.notoSans:
        return zh ? '思源黑体 (Noto Sans)' : 'Noto Sans';
      case AppFontFamily.inter:
        return zh ? 'Inter（英文字体）' : 'Inter';
      case AppFontFamily.custom:
        return zh ? '自定义（系统字体）' : 'Custom (system font)';
      case AppFontFamily.system:
        return zh ? '系统默认' : 'System default';
    }
  }

  String? get fontFamilyName {
    switch (this) {
      case AppFontFamily.notoSans:
        return 'Noto Sans';
      case AppFontFamily.inter:
        return 'Inter';
      case AppFontFamily.custom:
      case AppFontFamily.system:
        return null;
    }
  }

  static AppFontFamily parse(String? raw) {
    switch (raw) {
      case 'notoSans':
        return AppFontFamily.notoSans;
      case 'inter':
        return AppFontFamily.inter;
      case 'custom':
        return AppFontFamily.custom;
      case 'system':
      default:
        return AppFontFamily.system;
    }
  }
}

class AppSettings {
  final int reminderThresholdDays;
  final bool autoLaunch;
  final int textColorValue;
  final int backgroundColorValue;
  final int panelColorValue;
  final double surfaceOpacity;
  final int urgencyTintColorValue;
  final double urgencyOverlayOpacity;
  final String slogan;
  final bool showRecurringPanel;
  final int weeklyReminderDays;
  final int monthlyReminderDays;
  final AppLanguage language;
  final AppFontFamily fontFamily;
  final String? customFontFamily;

  const AppSettings({
    required this.reminderThresholdDays,
    required this.autoLaunch,
    required this.textColorValue,
    required this.backgroundColorValue,
    required this.panelColorValue,
    required this.surfaceOpacity,
    required this.urgencyTintColorValue,
    required this.urgencyOverlayOpacity,
    required this.slogan,
    required this.showRecurringPanel,
    required this.weeklyReminderDays,
    required this.monthlyReminderDays,
    required this.language,
    required this.fontFamily,
    required this.customFontFamily,
  });

  factory AppSettings.defaults() {
    return AppSettings(
      reminderThresholdDays: 3,
      autoLaunch: false,
      textColorValue: Colors.black.value,
      backgroundColorValue: const Color(0xFFF5F5F7).value,
      panelColorValue: Colors.white.value,
      surfaceOpacity: .92,
      urgencyTintColorValue: const Color(0xFFC98A72).value,
      urgencyOverlayOpacity: .10,
      slogan: '专注每一天',
      showRecurringPanel: true,
      weeklyReminderDays: 2,
      monthlyReminderDays: 3,
      language: AppLanguage.zh,
      fontFamily: AppFontFamily.notoSans,
      customFontFamily: null,
    );
  }

  AppSettings copyWith({
    int? reminderThresholdDays,
    bool? autoLaunch,
    int? textColorValue,
    int? backgroundColorValue,
    int? panelColorValue,
    double? surfaceOpacity,
    int? urgencyTintColorValue,
    double? urgencyOverlayOpacity,
    String? slogan,
    bool? showRecurringPanel,
    int? weeklyReminderDays,
    int? monthlyReminderDays,
    AppLanguage? language,
    AppFontFamily? fontFamily,
    String? customFontFamily,
  }) {
    return AppSettings(
      reminderThresholdDays: reminderThresholdDays ?? this.reminderThresholdDays,
      autoLaunch: autoLaunch ?? this.autoLaunch,
      textColorValue: textColorValue ?? this.textColorValue,
      backgroundColorValue: backgroundColorValue ?? this.backgroundColorValue,
      panelColorValue: panelColorValue ?? this.panelColorValue,
      surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
      urgencyTintColorValue: urgencyTintColorValue ?? this.urgencyTintColorValue,
      urgencyOverlayOpacity: urgencyOverlayOpacity ?? this.urgencyOverlayOpacity,
      slogan: slogan ?? this.slogan,
      showRecurringPanel: showRecurringPanel ?? this.showRecurringPanel,
      weeklyReminderDays: weeklyReminderDays ?? this.weeklyReminderDays,
      monthlyReminderDays: monthlyReminderDays ?? this.monthlyReminderDays,
      language: language ?? this.language,
      fontFamily: fontFamily ?? this.fontFamily,
      customFontFamily: customFontFamily ?? this.customFontFamily,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      reminderThresholdDays: json['reminderThresholdDays'] as int? ?? 3,
      autoLaunch: json['autoLaunch'] as bool? ?? false,
      textColorValue: json['textColorValue'] as int? ?? Colors.black.value,
      backgroundColorValue: json['backgroundColorValue'] as int? ?? const Color(0xFFF5F5F7).value,
      panelColorValue: json['panelColorValue'] as int? ?? Colors.white.value,
      surfaceOpacity: (json['surfaceOpacity'] as num?)?.toDouble() ?? .92,
      urgencyTintColorValue: json['urgencyTintColorValue'] as int? ?? const Color(0xFFC98A72).value,
      urgencyOverlayOpacity: (json['urgencyOverlayOpacity'] as num?)?.toDouble() ?? .10,
      slogan: json['slogan'] as String? ?? '专注每一天',
      showRecurringPanel: json['showRecurringPanel'] as bool? ?? true,
      weeklyReminderDays: json['weeklyReminderDays'] as int? ?? 2,
      monthlyReminderDays: json['monthlyReminderDays'] as int? ?? 3,
      language: AppLanguageX.parse(json['language'] as String?),
      fontFamily: AppFontFamilyX.parse(json['fontFamily'] as String?),
      customFontFamily: json['customFontFamily'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reminderThresholdDays': reminderThresholdDays,
      'autoLaunch': autoLaunch,
      'textColorValue': textColorValue,
      'backgroundColorValue': backgroundColorValue,
      'panelColorValue': panelColorValue,
      'surfaceOpacity': surfaceOpacity,
      'urgencyTintColorValue': urgencyTintColorValue,
      'urgencyOverlayOpacity': urgencyOverlayOpacity,
      'slogan': slogan,
      'showRecurringPanel': showRecurringPanel,
      'weeklyReminderDays': weeklyReminderDays,
      'monthlyReminderDays': monthlyReminderDays,
      'language': language.storageKey,
      'fontFamily': fontFamily.storageKey,
      'customFontFamily': customFontFamily,
    };
  }

  Color get textColor => Color(textColorValue);
  Color get backgroundColor => Color(backgroundColorValue);
  Color get panelColor => Color(panelColorValue);
  Color get urgencyTintColor => Color(urgencyTintColorValue);

  String? get resolvedFontFamily {
    if (fontFamily == AppFontFamily.custom) {
      final trimmed = customFontFamily?.trim();
      if (trimmed == null || trimmed.isEmpty) {
        return null;
      }
      return trimmed;
    }
    return fontFamily.fontFamilyName;
  }
}
