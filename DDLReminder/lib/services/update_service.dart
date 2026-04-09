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
  static const String _latestReleaseUrl =
      'https://github.com/$owner/$repo/releases/latest';
  static const String _latestAssetUrl =
      'https://github.com/$owner/$repo/releases/latest/download/$releaseAssetName';

  Future<String> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    final version = info.version.trim();
    final buildNumber = info.buildNumber.trim();

    if (version.isEmpty) {
      return buildNumber.isEmpty ? '0.0.0+0' : '0.0.0+$buildNumber';
    }
    if (buildNumber.isEmpty || version.contains('+')) {
      return version;
    }
    return '$version+$buildNumber';
  }

  Future<UpdateCheckResult> checkForUpdate() async {
    final current = await currentVersion();
    final client = HttpClient()..userAgent = 'DDLreminder-Updater';

    try {
      final latestReleaseResponse = await _sendWithoutRedirect(
        client,
        Uri.parse(_latestReleaseUrl),
      );
      if (!_isRedirect(latestReleaseResponse.statusCode)) {
        return UpdateCheckResult(
          currentVersion: current,
          hasUpdate: false,
          message:
              'GitHub latest release returned ${latestReleaseResponse.statusCode}',
        );
      }

      final releaseLocation = latestReleaseResponse.headers.value(
        HttpHeaders.locationHeader,
      );
      if (releaseLocation == null || releaseLocation.trim().isEmpty) {
        return UpdateCheckResult(
          currentVersion: current,
          hasUpdate: false,
          message: 'GitHub latest release did not provide a redirect target',
        );
      }

      final releaseUri = _resolveRedirect(
        Uri.parse(_latestReleaseUrl),
        releaseLocation,
      );
      final tag = releaseUri.pathSegments.isNotEmpty
          ? releaseUri.pathSegments.last.trim()
          : '';
      final version = _normalizeVersion(tag);

      if (tag.isEmpty || version.isEmpty) {
        return UpdateCheckResult(
          currentVersion: current,
          hasUpdate: false,
          message: 'Unable to resolve the latest release version from GitHub',
        );
      }

      final assetResponse = await _sendWithoutRedirect(
        client,
        Uri.parse(_latestAssetUrl),
      );
      if (!_isSuccessOrRedirect(assetResponse.statusCode)) {
        return UpdateCheckResult(
          currentVersion: current,
          hasUpdate: false,
          message:
              'Latest release asset is unavailable: $releaseAssetName (${assetResponse.statusCode})',
        );
      }

      final release = UpdateRelease(
        tag: tag,
        version: version,
        assetName: releaseAssetName,
        assetDownloadUrl: _latestAssetUrl,
        htmlUrl: releaseUri.toString(),
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

  Future<HttpClientResponse> _sendWithoutRedirect(
    HttpClient client,
    Uri uri,
  ) async {
    final request = await client.getUrl(uri);
    request.followRedirects = false;
    return request.close();
  }

  bool _isRedirect(int statusCode) =>
      statusCode == HttpStatus.movedTemporarily ||
      statusCode == HttpStatus.found ||
      statusCode == HttpStatus.seeOther ||
      statusCode == HttpStatus.temporaryRedirect ||
      statusCode == HttpStatus.permanentRedirect;

  bool _isSuccessOrRedirect(int statusCode) =>
      (statusCode >= 200 && statusCode < 300) || _isRedirect(statusCode);

  Uri _resolveRedirect(Uri base, String location) => base.resolve(location);

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
        exeFile.uri.pathSegments.isNotEmpty
            ? exeFile.uri.pathSegments.last
            : 'DDLReminder.exe',
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
    final numbers = versionPart
        .split('.')
        .map((item) => int.tryParse(item) ?? 0)
        .toList(growable: true);
    while (numbers.length < 3) {
      numbers.add(0);
    }
    return [numbers[0], numbers[1], numbers[2], buildPart];
  }
}
