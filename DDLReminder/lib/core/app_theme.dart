import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_settings.dart';

ThemeData buildTheme(AppSettings settings) {
  final base = ThemeData.light();
  final resolvedTextTheme = _resolveTextTheme(settings, base.textTheme);
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: settings.textColor,
      secondary: settings.backgroundColor,
      surface: settings.panelColor,
      onSurface: settings.textColor,
    ),
    scaffoldBackgroundColor: settings.backgroundColor,
    canvasColor: settings.backgroundColor,
    cardColor: settings.panelColor,
    textTheme: resolvedTextTheme,
    primaryTextTheme: resolvedTextTheme,
    iconTheme: base.iconTheme.copyWith(color: settings.textColor),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      labelStyle: TextStyle(color: settings.textColor.withOpacity(.7)),
      prefixStyle: TextStyle(color: settings.textColor.withOpacity(.7)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: settings.textColor.withOpacity(.2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: settings.textColor.withOpacity(.4))),
    ),
    checkboxTheme: const CheckboxThemeData(shape: CircleBorder()),
    dialogTheme: DialogThemeData(
      backgroundColor: settings.panelColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

TextTheme _resolveTextTheme(AppSettings settings, TextTheme base) {
  TextTheme themed;
  switch (settings.fontFamily) {
    case AppFontFamily.notoSans:
      themed = GoogleFonts.notoSansTextTheme(base);
      break;
    case AppFontFamily.inter:
      themed = GoogleFonts.interTextTheme(base);
      break;
    case AppFontFamily.custom:
      final customFamily = settings.resolvedFontFamily;
      themed = customFamily == null ? base : base.apply(fontFamily: customFamily);
      break;
    case AppFontFamily.system:
    default:
      themed = base;
      break;
  }
  final tinted = themed.apply(bodyColor: settings.textColor, displayColor: settings.textColor);
  return _boldenTextTheme(tinted);
}

TextTheme _boldenTextTheme(TextTheme theme) {
  TextStyle? bold(TextStyle? style) => style?.copyWith(fontWeight: FontWeight.w600);
  return theme.copyWith(
    displayLarge: bold(theme.displayLarge),
    displayMedium: bold(theme.displayMedium),
    displaySmall: bold(theme.displaySmall),
    headlineLarge: bold(theme.headlineLarge),
    headlineMedium: bold(theme.headlineMedium),
    headlineSmall: bold(theme.headlineSmall),
    titleLarge: bold(theme.titleLarge),
    titleMedium: bold(theme.titleMedium),
    titleSmall: bold(theme.titleSmall),
    bodyLarge: bold(theme.bodyLarge),
    bodyMedium: bold(theme.bodyMedium),
    bodySmall: bold(theme.bodySmall),
    labelLarge: bold(theme.labelLarge),
    labelMedium: bold(theme.labelMedium),
    labelSmall: bold(theme.labelSmall),
  );
}
