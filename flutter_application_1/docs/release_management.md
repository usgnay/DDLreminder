# Release Management

## Version source of truth

- The app version is defined only in `pubspec.yaml`.
- Format: `major.minor.patch+build`.
- Example: `1.0.0+1`.

## Release rules

- Every public Windows release must use a Git tag that matches the app version.
- Tag format: `v<pubspec version without spaces>`.
- Example: `v1.0.0+1`.

## Windows release asset

- GitHub Releases asset name is fixed:
- `DDLreminder-windows-release.zip`

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
- generate `dist\DDLreminder-windows-release.zip`

## GitHub release steps

Preferred:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\publish_github_release.ps1
```

This script will:

- verify version from `pubspec.yaml`
- optionally run the build script
- create and push tag `v<version>`
- create or update the GitHub Release
- upload `dist\DDLreminder-windows-release.zip`

Authentication:

- Preferred: GitHub CLI `gh`
- Fallback: set `GITHUB_TOKEN` or `GH_TOKEN`

Manual steps if needed:

1. Update `pubspec.yaml` version.
2. Run `flutter pub get` if needed.
3. Run `.\scripts\build_release.ps1`.
4. Commit changes.
5. Create tag `v<version>`.
6. Push commit and tag.
7. Create a GitHub Release from that tag.
8. Upload `dist\DDLreminder-windows-release.zip`.

## App update behavior

- The app checks GitHub latest release.
- It compares the current installed version with the latest tag.
- If a newer version exists, it runs `scripts\update_from_github.ps1`.
- The updater replaces the current app directory contents and restarts the app.

## Compatibility note

- The updater assumes the distributed app directory contains:
  - `DDLreminder.exe`
  - Flutter runtime files
  - `scripts\update_from_github.ps1`

If you change the distribution structure, update the updater script and this document together.
