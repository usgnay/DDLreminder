import 'package:flutter/material.dart';

const Object _unsetValue = Object();

enum AppLanguage { zh, en }

enum AppFontFamily { system, notoSans, inter, custom }

enum BackgroundMode { color, image }

enum BackgroundImageFit { cover, contain }

enum BackgroundImageAnchor {
  center,
  top,
  bottom,
  left,
  right,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

extension AppLanguageX on AppLanguage {
  String get localeCode => this == AppLanguage.zh ? 'zh_CN' : 'en_US';
  String get displayName => this == AppLanguage.zh ? '中文' : 'English';
  String get storageKey => this == AppLanguage.zh ? 'zh' : 'en';

  static AppLanguage parse(String? raw) => raw == 'en' ? AppLanguage.en : AppLanguage.zh;
}

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
      default:
        return AppFontFamily.system;
    }
  }
}

extension BackgroundModeX on BackgroundMode {
  String get storageKey => this == BackgroundMode.image ? 'image' : 'color';

  static BackgroundMode parse(String? raw) => raw == 'image' ? BackgroundMode.image : BackgroundMode.color;
}

extension BackgroundImageFitX on BackgroundImageFit {
  String get storageKey => this == BackgroundImageFit.contain ? 'contain' : 'cover';

  static BackgroundImageFit parse(String? raw) => raw == 'contain' ? BackgroundImageFit.contain : BackgroundImageFit.cover;
}

extension BackgroundImageAnchorX on BackgroundImageAnchor {
  String get storageKey {
    switch (this) {
      case BackgroundImageAnchor.top:
        return 'top';
      case BackgroundImageAnchor.bottom:
        return 'bottom';
      case BackgroundImageAnchor.left:
        return 'left';
      case BackgroundImageAnchor.right:
        return 'right';
      case BackgroundImageAnchor.topLeft:
        return 'topLeft';
      case BackgroundImageAnchor.topRight:
        return 'topRight';
      case BackgroundImageAnchor.bottomLeft:
        return 'bottomLeft';
      case BackgroundImageAnchor.bottomRight:
        return 'bottomRight';
      case BackgroundImageAnchor.center:
        return 'center';
    }
  }

  Alignment get alignment {
    switch (this) {
      case BackgroundImageAnchor.top:
        return Alignment.topCenter;
      case BackgroundImageAnchor.bottom:
        return Alignment.bottomCenter;
      case BackgroundImageAnchor.left:
        return Alignment.centerLeft;
      case BackgroundImageAnchor.right:
        return Alignment.centerRight;
      case BackgroundImageAnchor.topLeft:
        return Alignment.topLeft;
      case BackgroundImageAnchor.topRight:
        return Alignment.topRight;
      case BackgroundImageAnchor.bottomLeft:
        return Alignment.bottomLeft;
      case BackgroundImageAnchor.bottomRight:
        return Alignment.bottomRight;
      case BackgroundImageAnchor.center:
        return Alignment.center;
    }
  }

  static BackgroundImageAnchor parse(String? raw) {
    switch (raw) {
      case 'top':
        return BackgroundImageAnchor.top;
      case 'bottom':
        return BackgroundImageAnchor.bottom;
      case 'left':
        return BackgroundImageAnchor.left;
      case 'right':
        return BackgroundImageAnchor.right;
      case 'topLeft':
        return BackgroundImageAnchor.topLeft;
      case 'topRight':
        return BackgroundImageAnchor.topRight;
      case 'bottomLeft':
        return BackgroundImageAnchor.bottomLeft;
      case 'bottomRight':
        return BackgroundImageAnchor.bottomRight;
      default:
        return BackgroundImageAnchor.center;
    }
  }
}

class AppSettings {
  const AppSettings({
    required this.reminderThresholdDays,
    required this.autoLaunch,
    required this.textColorValue,
    required this.backgroundColorValue,
    required this.panelColorValue,
    required this.surfaceOpacity,
    required this.backgroundMode,
    required this.backgroundImagePath,
    required this.backgroundImageFit,
    required this.backgroundImageAnchor,
    required this.backgroundImageFocusX,
    required this.backgroundImageFocusY,
    required this.backgroundImageOpacity,
    required this.backgroundImageOverlayOpacity,
    required this.backgroundImageOverlayColorValue,
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

  final int reminderThresholdDays;
  final bool autoLaunch;
  final int textColorValue;
  final int backgroundColorValue;
  final int panelColorValue;
  final double surfaceOpacity;
  final BackgroundMode backgroundMode;
  final String? backgroundImagePath;
  final BackgroundImageFit backgroundImageFit;
  final BackgroundImageAnchor backgroundImageAnchor;
  final double backgroundImageFocusX;
  final double backgroundImageFocusY;
  final double backgroundImageOpacity;
  final double backgroundImageOverlayOpacity;
  final int backgroundImageOverlayColorValue;
  final int urgencyTintColorValue;
  final double urgencyOverlayOpacity;
  final String slogan;
  final bool showRecurringPanel;
  final int weeklyReminderDays;
  final int monthlyReminderDays;
  final AppLanguage language;
  final AppFontFamily fontFamily;
  final String? customFontFamily;

  factory AppSettings.defaults() {
    return AppSettings(
      reminderThresholdDays: 3,
      autoLaunch: false,
      textColorValue: Colors.black.value,
      backgroundColorValue: const Color(0xFFF5F5F7).value,
      panelColorValue: Colors.white.value,
      surfaceOpacity: .92,
      backgroundMode: BackgroundMode.color,
      backgroundImagePath: null,
      backgroundImageFit: BackgroundImageFit.cover,
      backgroundImageAnchor: BackgroundImageAnchor.center,
      backgroundImageFocusX: 0,
      backgroundImageFocusY: 0,
      backgroundImageOpacity: .78,
      backgroundImageOverlayOpacity: .12,
      backgroundImageOverlayColorValue: Colors.black.value,
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
    BackgroundMode? backgroundMode,
    Object? backgroundImagePath = _unsetValue,
    BackgroundImageFit? backgroundImageFit,
    BackgroundImageAnchor? backgroundImageAnchor,
    double? backgroundImageFocusX,
    double? backgroundImageFocusY,
    double? backgroundImageOpacity,
    double? backgroundImageOverlayOpacity,
    int? backgroundImageOverlayColorValue,
    int? urgencyTintColorValue,
    double? urgencyOverlayOpacity,
    String? slogan,
    bool? showRecurringPanel,
    int? weeklyReminderDays,
    int? monthlyReminderDays,
    AppLanguage? language,
    AppFontFamily? fontFamily,
    Object? customFontFamily = _unsetValue,
  }) {
    return AppSettings(
      reminderThresholdDays: reminderThresholdDays ?? this.reminderThresholdDays,
      autoLaunch: autoLaunch ?? this.autoLaunch,
      textColorValue: textColorValue ?? this.textColorValue,
      backgroundColorValue: backgroundColorValue ?? this.backgroundColorValue,
      panelColorValue: panelColorValue ?? this.panelColorValue,
      surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
      backgroundMode: backgroundMode ?? this.backgroundMode,
      backgroundImagePath: identical(backgroundImagePath, _unsetValue) ? this.backgroundImagePath : backgroundImagePath as String?,
      backgroundImageFit: backgroundImageFit ?? this.backgroundImageFit,
      backgroundImageAnchor: backgroundImageAnchor ?? this.backgroundImageAnchor,
      backgroundImageFocusX: backgroundImageFocusX ?? this.backgroundImageFocusX,
      backgroundImageFocusY: backgroundImageFocusY ?? this.backgroundImageFocusY,
      backgroundImageOpacity: backgroundImageOpacity ?? this.backgroundImageOpacity,
      backgroundImageOverlayOpacity: backgroundImageOverlayOpacity ?? this.backgroundImageOverlayOpacity,
      backgroundImageOverlayColorValue: backgroundImageOverlayColorValue ?? this.backgroundImageOverlayColorValue,
      urgencyTintColorValue: urgencyTintColorValue ?? this.urgencyTintColorValue,
      urgencyOverlayOpacity: urgencyOverlayOpacity ?? this.urgencyOverlayOpacity,
      slogan: slogan ?? this.slogan,
      showRecurringPanel: showRecurringPanel ?? this.showRecurringPanel,
      weeklyReminderDays: weeklyReminderDays ?? this.weeklyReminderDays,
      monthlyReminderDays: monthlyReminderDays ?? this.monthlyReminderDays,
      language: language ?? this.language,
      fontFamily: fontFamily ?? this.fontFamily,
      customFontFamily: identical(customFontFamily, _unsetValue) ? this.customFontFamily : customFontFamily as String?,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final imagePath = (json['backgroundImagePath'] as String?)?.trim();
    final parsedAnchor = BackgroundImageAnchorX.parse(json['backgroundImageAnchor'] as String?);
    return AppSettings(
      reminderThresholdDays: json['reminderThresholdDays'] as int? ?? 3,
      autoLaunch: json['autoLaunch'] as bool? ?? false,
      textColorValue: json['textColorValue'] as int? ?? Colors.black.value,
      backgroundColorValue: json['backgroundColorValue'] as int? ?? const Color(0xFFF5F5F7).value,
      panelColorValue: json['panelColorValue'] as int? ?? Colors.white.value,
      surfaceOpacity: (json['surfaceOpacity'] as num?)?.toDouble() ?? .92,
      backgroundMode: BackgroundModeX.parse(json['backgroundMode'] as String?),
      backgroundImagePath: (imagePath == null || imagePath.isEmpty) ? null : imagePath,
      backgroundImageFit: BackgroundImageFitX.parse(json['backgroundImageFit'] as String?),
      backgroundImageAnchor: parsedAnchor,
      backgroundImageFocusX: (json['backgroundImageFocusX'] as num?)?.toDouble() ?? parsedAnchor.alignment.x,
      backgroundImageFocusY: (json['backgroundImageFocusY'] as num?)?.toDouble() ?? parsedAnchor.alignment.y,
      backgroundImageOpacity: (json['backgroundImageOpacity'] as num?)?.toDouble() ?? .78,
      backgroundImageOverlayOpacity: (json['backgroundImageOverlayOpacity'] as num?)?.toDouble() ?? .12,
      backgroundImageOverlayColorValue: json['backgroundImageOverlayColorValue'] as int? ?? Colors.black.value,
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
      'backgroundMode': backgroundMode.storageKey,
      'backgroundImagePath': backgroundImagePath,
      'backgroundImageFit': backgroundImageFit.storageKey,
      'backgroundImageAnchor': backgroundImageAnchor.storageKey,
      'backgroundImageFocusX': backgroundImageFocusX,
      'backgroundImageFocusY': backgroundImageFocusY,
      'backgroundImageOpacity': backgroundImageOpacity,
      'backgroundImageOverlayOpacity': backgroundImageOverlayOpacity,
      'backgroundImageOverlayColorValue': backgroundImageOverlayColorValue,
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
  Color get backgroundImageOverlayColor => Color(backgroundImageOverlayColorValue);
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
