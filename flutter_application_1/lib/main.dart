import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/app_theme.dart';
import 'models/app_settings.dart';
import 'services/bootstrap.dart';
import 'ui/shell/desktop_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    initializeDateFormatting('zh_CN', null),
    initializeDateFormatting('en_US', null),
  ]);
  final container = await bootstrapApp();
  Intl.defaultLocale = container.settings.value.language.localeCode;
  runApp(TaskWidgetApp(container: container));
}

class TaskWidgetApp extends StatelessWidget {
  const TaskWidgetApp({super.key, required this.container});

  final ServiceContainer container;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: container.settings,
      builder: (context, _) {
        final currentSettings = container.settings.value;
        Intl.defaultLocale = currentSettings.language.localeCode;
        final locale = currentSettings.language == AppLanguage.zh
            ? const Locale('zh', 'CN')
            : const Locale('en', 'US');
        return MaterialApp(
          title: 'DDLreminder',
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('zh', 'CN'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildTheme(currentSettings),
          home: DesktopShell(container: container),
        );
      },
    );
  }
}
