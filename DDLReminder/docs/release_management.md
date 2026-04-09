# Release Management

## Version source of truth

- The app version is defined only in `pubspec.yaml`.
- Format: `major.minor.patch+build`.
- Example: `1.0.0+1`.

## Version bump workflow

Use the dedicated version script before publishing:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bump_version.ps1 -Part build
```

Supported options:

- `-Part build`
- `-Part patch`
- `-Part minor`
- `-Part major`
- `-SetVersion 1.2.0+5`

Rules:

- `build`: only increments the build number
- `patch`: increments patch and resets build to `1`
- `minor`: increments minor, resets patch to `0`, resets build to `1`
- `major`: increments major, resets minor and patch to `0`, resets build to `1`

The script prints:

- old version
- new version
- suggested tag

## Release rules

- Every public Windows release must use a Git tag that matches the app version.
- Tag format: `v<pubspec version>`.
- Example: `v1.0.0+1`.

## Windows release asset

- GitHub Releases asset name is fixed:
- `DDLReminder-windows-release.zip`

Do not rename this asset unless you also update:

- `lib/services/update_service.dart`
- `scripts/update_from_github.ps1`
- `scripts/build_release.ps1`
- this document

## Build steps

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_release.ps1
```

This script will:

- build Windows release output
- copy the updater script into `Release\scripts`
- generate `dist\DDLReminder-windows-release.zip`

## GitHub release steps

Preferred:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\publish_github_release.ps1 -Bump build
```

Or double-click:

- `scripts\publish_github_release.bat`

This script now supports:

- automatic version bumping through `-Bump`
- explicit version setting through `-SetVersion`
- version format validation
- dynamic target branch detection
- remote tag collision checks
- optional tracked-change auto-commit

Optional parameters:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\publish_github_release.ps1 -Bump patch -ReleaseNotes "Bug fixes and UI polish"
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\publish_github_release.ps1 -SetVersion 1.2.0+5 -Token "<github token>"
```

Authentication:

- Preferred: GitHub CLI `gh`
- Fallback: set `GITHUB_TOKEN` or `GH_TOKEN`
- Interactive fallback: enter a token in `publish_github_release.bat`

## App update behavior

- The app checks GitHub latest release.
- The local app version is resolved as `version+buildNumber`.
- The app compares the full version against the latest release tag.
- If a newer version exists, it runs `scripts\update_from_github.ps1`.

The updater now uses a safer workflow:

- download into a temp directory
- extract into a temp directory
- validate the package layout before touching the installed app
- copy into staging and validate again
- stop the running app only after validation succeeds
- back up the current install
- install the staged package
- roll back automatically if installation fails
- write updater logs to `%TEMP%\DDLReminder-updater\update.log`

## Manual steps if needed

1. Update `pubspec.yaml` version, or run `.\scripts\bump_version.ps1`.
2. Run `.\scripts\build_release.ps1`.
3. Commit changes.
4. Create tag `v<version>`.
5. Push commit and tag.
6. Create a GitHub Release from that tag.
7. Upload `dist\DDLReminder-windows-release.zip`.

## Compatibility note

- The updater assumes the distributed app directory contains:
  - `DDLReminder.exe`
  - Flutter runtime files
  - `data\flutter_assets`
  - `scripts\update_from_github.ps1`

If you change the distribution structure, update the updater script and this document together.
