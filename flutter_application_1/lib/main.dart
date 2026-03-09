import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/app_theme.dart';
import 'services/bootstrap.dart';
import 'ui/shell/desktop_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN', null);
  Intl.defaultLocale = 'zh_CN';
  final container = await bootstrapApp();
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
        return MaterialApp(
          title: 'DDLreminder',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(container.settings.value),
          home: DesktopShell(container: container),
        );
      },
    );
  }
}
