import 'dart:io';

import 'package:flutter/services.dart';

class SystemShellService {
  static const MethodChannel _channel = MethodChannel('ddlreminder/system_shell');

  Future<void> showReminderNotification({
    required String title,
    required String body,
  }) async {
    if (!Platform.isWindows) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('showReminderNotification', {
        'title': title,
        'body': body,
      });
    } catch (_) {
      // Native shell integration is optional.
    }
  }
}
