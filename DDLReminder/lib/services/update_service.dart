import 'dart:convert';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

class UpdateRelease {
  const UpdateRelease({
    required this.tag,
    required this.version,
    required this.assetName,
    required this.assetDownloadUrl,
    required this.htmlUrl,
  });

  final String tag;
  final String version;
  final String assetName;
  final String assetDownloadUrl;
  final String htmlUrl;
}

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.currentVersion,
    required this.hasUpdate,
    this.release,
    this.message,
  });

  final String currentVersion;
  final bool hasUpdate;
  final UpdateRelease? release;
  final String? message;
}

class UpdateService {
  static const String owner = 'usgnay';
  static const String repo = 'DDLreminder';
  static const String releaseAssetName = 'DDLReminder-windows-release.zip';

  Future<String> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  Future<UpdateCheckResult> checkForUpdate() async {
    final current = await currentVersion();
    final client = HttpClient()..userAgent = 'DDLreminder-Updater';

    try {
      final request = await client.getUrl(
        Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest'),
      );
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return UpdateCheckResult(
          currentVersion: current,
          hasUpdate: false,
          message: 'GitHub API returned ${response.statusCode}',
        );
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final tag = (json['tag_name'] as String? ?? '').trim();
      final version = _normalizeVersion(tag);
      final htmlUrl = (json['html_url'] as String? ?? '').trim();
      final assets = (json['assets'] as List<dynamic>? ?? const []);
      final asset = assets.cast<Map<String, dynamic>?>().firstWhere(
            (item) => item?['name'] == releaseAssetName,
            orElse: () => null,
          );

      if (asset == null) {
        return UpdateCheckResult(
          currentVersion: current,
          hasUpdate: false,
          message: 'Missing asset: $releaseAssetName',
        );
      }

      final release = UpdateRelease(
        tag: tag,
        version: version,
        assetName: asset['name'] as String,
        assetDownloadUrl: asset['browser_download_url'] as String,
        htmlUrl: htmlUrl,
      );

      final hasUpdate = _compareVersions(version, current) > 0;
      return UpdateCheckResult(
        currentVersion: current,
        hasUpdate: hasUpdate,
        release: release,
      );
    } catch (error) {
      return UpdateCheckResult(
        currentVersion: current,
        hasUpdate: false,
        message: error.toString(),
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<void> startUpdate(UpdateRelease release) async {
    if (!Platform.isWindows) {
      throw UnsupportedError('GitHub updater currently supports Windows only.');
    }

    final exePath = Platform.resolvedExecutable;
    final exeFile = File(exePath);
    final appDir = exeFile.parent.path;
    final scriptFile = File('$appDir\\scripts\\update_from_github.ps1');
    if (!scriptFile.existsSync()) {
      throw StateError('Updater script not found: ${scriptFile.path}');
    }

    await Process.start(
      'powershell.exe',
      [
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        scriptFile.path,
        '-RepoOwner',
        owner,
        '-RepoName',
        repo,
        '-AssetName',
        release.assetName,
        '-AppDir',
        appDir,
        '-ExeName',
      exeFile.uri.pathSegments.isNotEmpty ? exeFile.uri.pathSegments.last : 'DDLReminder.exe',
        '-CurrentVersion',
        await currentVersion(),
      ],
      mode: ProcessStartMode.detached,
      runInShell: false,
    );
  }

  String _normalizeVersion(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('v') || trimmed.startsWith('V')) {
      return trimmed.substring(1);
    }
    return trimmed;
  }

  int _compareVersions(String a, String b) {
    final left = _parseVersionParts(a);
    final right = _parseVersionParts(b);
    for (var i = 0; i < 3; i++) {
      final diff = left[i] - right[i];
      if (diff != 0) {
        return diff;
      }
    }
    final buildDiff = left[3] - right[3];
    if (buildDiff != 0) {
      return buildDiff;
    }
    return 0;
  }

  List<int> _parseVersionParts(String value) {
    final normalized = _normalizeVersion(value);
    final split = normalized.split('+');
    final versionPart = split.first;
    final buildPart = split.length > 1 ? int.tryParse(split[1]) ?? 0 : 0;
    final numbers = versionPart.split('.').map((item) => int.tryParse(item) ?? 0).toList(growable: true);
    while (numbers.length < 3) {
      numbers.add(0);
    }
    return [numbers[0], numbers[1], numbers[2], buildPart];
  }
}
