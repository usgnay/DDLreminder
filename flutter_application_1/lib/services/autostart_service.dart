import 'dart:io';

class AutostartService {
  static const _appName = 'DDLreminder';

  Future<void> apply({required bool enable}) async {
    final executable = Platform.resolvedExecutable;
    if (Platform.isWindows) {
      await _handleWindows(enable, executable);
    } else if (Platform.isMacOS) {
      await _handleMac(enable, executable);
    } else if (Platform.isLinux) {
      await _handleLinux(enable, executable);
    }
  }

  Future<void> _handleWindows(bool enable, String executable) async {
    const key = r'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run';
    final args = enable
      ? ['add', key, '/v', _appName, '/t', 'REG_SZ', '/d', executable, '/f']
        : ['delete', key, '/v', _appName, '/f'];
    try {
      await Process.run('reg', args);
    } catch (_) {
      // Ignore failures; app will still honor stored preference.
    }
  }

  Future<void> _handleMac(bool enable, String executable) async {
    final launchAgents = Directory('${Platform.environment['HOME']}/Library/LaunchAgents');
    if (!await launchAgents.exists()) {
      await launchAgents.create(recursive: true);
    }
    final plist = File('${launchAgents.path}/com.desktop.taskwidget.plist');
    if (!enable) {
      if (await plist.exists()) {
        await plist.delete();
      }
      return;
    }
    final contents = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.desktop.taskwidget</string>
  <key>ProgramArguments</key>
  <array>
    <string>$executable</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
''';
    await plist.writeAsString(contents, flush: true);
  }

  Future<void> _handleLinux(bool enable, String executable) async {
    final autoDir = Directory('${Platform.environment['HOME']}/.config/autostart');
    if (!await autoDir.exists()) {
      await autoDir.create(recursive: true);
    }
    final desktopFile = File('${autoDir.path}/desktop_task_widget.desktop');
    if (!enable) {
      if (await desktopFile.exists()) {
        await desktopFile.delete();
      }
      return;
    }
    final contents = '''
[Desktop Entry]
Type=Application
Exec=$executable
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=DDLreminder
Comment=Lightweight task reminder
''';
    await desktopFile.writeAsString(contents, flush: true);
  }
}
