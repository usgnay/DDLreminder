import 'dart:convert';
import 'dart:io';

/// Service that enumerates installed font families on the current platform.
class FontService {
  FontService();

  static const _windowsFontRegistryKey =
      r'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts';

  List<String>? _cachedFonts;

  /// Whether the current platform supports enumerating native fonts.
  bool get isEnumerationSupported => Platform.isWindows;

  /// Returns the list of installed font families (if supported).
  Future<List<String>> installedFonts() async {
    if (_cachedFonts != null) {
      return _cachedFonts!;
    }
    if (!isEnumerationSupported) {
      _cachedFonts = const [];
      return _cachedFonts!;
    }
    _cachedFonts = await _loadWindowsFonts();
    return _cachedFonts!;
  }

  Future<List<String>> _loadWindowsFonts() async {
    try {
      final result = await Process.run('reg', ['query', _windowsFontRegistryKey]);
      if (result.exitCode != 0) {
        return const [];
      }
      final stdoutStr = result.stdout is String
          ? result.stdout as String
          : utf8.decode(result.stdout as List<int>);
      final fonts = <String>{};
      for (final rawLine in const LineSplitter().convert(stdoutStr)) {
        final line = rawLine.trim();
        if (line.isEmpty) {
          continue;
        }
        final regIndex = line.indexOf('REG_');
        if (regIndex <= 0) {
          continue;
        }
        final namePart = line.substring(0, regIndex).trim();
        if (namePart.isEmpty) {
          continue;
        }
        final cleaned = _normalizeFontName(namePart);
        if (cleaned.isNotEmpty) {
          fonts.add(cleaned);
        }
      }
      final sorted = fonts.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return sorted;
    } catch (_) {
      return const [];
    }
  }

  String _normalizeFontName(String input) {
    var name = input;
    final parenIndex = name.indexOf('(');
    if (parenIndex > 0) {
      name = name.substring(0, parenIndex);
    }
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    return name;
  }
}
