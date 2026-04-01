import 'dart:io';

class AutostartService {
  static const _appName = 'DDLReminder';
  static const _windowsLauncherDirName = 'DDLReminder';
  static const _windowsStartupScriptName = 'DDLReminder Startup.cmd';
  static const _windowsTargetFileName = 'autostart_target.txt';

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
    final appData = Platform.environment['APPDATA'];
    if (appData == null || appData.isEmpty) {
      return;
    }

    final startupDir = Directory('$appData\\Microsoft\\Windows\\Start Menu\\Programs\\Startup');
    final launcherDir = Directory('$appData\\$_windowsLauncherDirName');
    final startupScript = File('${startupDir.path}\\$_windowsStartupScriptName');
    final targetFile = File('${launcherDir.path}\\$_windowsTargetFileName');

    try {
      if (!enable) {
        if (await startupScript.exists()) {
          await startupScript.delete();
        }
        if (await targetFile.exists()) {
          await targetFile.delete();
        }
        return;
      }

      if (!await startupDir.exists()) {
        await startupDir.create(recursive: true);
      }
      if (!await launcherDir.exists()) {
        await launcherDir.create(recursive: true);
      }

      await targetFile.writeAsString(executable, flush: true);
      await startupScript.writeAsString(_buildWindowsStartupScript(targetFile.path), flush: true);
    } catch (_) {
      // Ignore failures; app will still honor stored preference.
    }
  }

  String _buildWindowsStartupScript(String targetFilePath) {
    final escapedTargetFilePath = targetFilePath.replaceAll('%', '%%');
    return '''
@echo off
setlocal
set "TARGET_FILE=$escapedTargetFilePath"
if not exist "%TARGET_FILE%" exit /b 0
set /p TARGET=<"%TARGET_FILE%"
if not defined TARGET exit /b 0
if not exist "%TARGET%" exit /b 0
start "" "%TARGET%"
''';
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
Name=DDLReminder
Comment=Lightweight task reminder
''';
    await desktopFile.writeAsString(contents, flush: true);
  }
}
