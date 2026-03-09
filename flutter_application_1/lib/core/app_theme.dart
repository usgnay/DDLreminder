import 'package:flutter/material.dart';
import '../models/app_settings.dart';

ThemeData buildTheme(AppSettings settings) {
  final base = ThemeData.light();
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
    textTheme: base.textTheme.apply(bodyColor: settings.textColor, displayColor: settings.textColor),
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
