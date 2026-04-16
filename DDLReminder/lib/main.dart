import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/app_theme.dart';
import 'models/app_settings.dart';
import 'providers/app_providers.dart';
import 'services/bootstrap.dart';
import 'ui/shell/desktop_shell.dart';
import 'ui/shell/mobile_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    initializeDateFormatting('zh_CN', null),
    initializeDateFormatting('en_US', null),
  ]);
  final container = await bootstrapApp();
  Intl.defaultLocale = container.settings.value.language.localeCode;
  runApp(
    ProviderScope(
      overrides: [serviceContainerProvider.overrideWithValue(container)],
      child: const TaskWidgetApp(),
    ),
  );
}

class TaskWidgetApp extends ConsumerWidget {
  const TaskWidgetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSettings = ref.watch(appSettingsProvider);
    Intl.defaultLocale = currentSettings.language.localeCode;
    final locale = currentSettings.language == AppLanguage.zh
        ? const Locale('zh', 'CN')
        : const Locale('en', 'US');
    return MaterialApp(
      title: 'DDLReminder',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('en', 'US'), Locale('zh', 'CN')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(currentSettings),
      home: _buildHome(ref),
    );
  }

  Widget _buildHome(WidgetRef ref) {
    if (kIsWeb) {
      return const MobileShell();
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return const MobileShell();
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return const DesktopShell();
      case TargetPlatform.fuchsia:
        return const MobileShell();
    }
  }
}
