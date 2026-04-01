Project notes for code agents:

- Flutter SDK is installed at `E:\flutter`.
- When running Flutter commands from an agent/tooling environment, prefer `E:\flutter\bin\flutter.bat` because agent shells may not inherit the user's interactive PATH.
- Flutter app lives in `C:\Users\DELL\Desktop\testflt\flutter_application_1`.
- Version management must follow `C:\Users\DELL\Desktop\testflt\flutter_application_1\docs\release_management.md`.
- The app version source of truth is `flutter_application_1/pubspec.yaml`.
- Public GitHub release tag format is `v<pubspec version>`.
- Windows release asset name is fixed as `DDLreminder-windows-release.zip`.
- Windows release build script is `flutter_application_1\scripts\build_release.ps1`.
- GitHub publish script is `flutter_application_1\scripts\publish_github_release.ps1`.
- Publishing should prefer `gh`; otherwise use `GITHUB_TOKEN` or `GH_TOKEN`.
