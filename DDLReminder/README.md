# DDLReminder

## 简介 | Overview

DDLReminder 是一个基于 Flutter 的轻量桌面任务提醒应用，适合记录普通截止任务和周期性任务，并通过紧凑的桌面界面持续查看近期安排。

DDLReminder is a lightweight desktop task reminder built with Flutter. It helps you manage one-off deadlines and recurring tasks in a compact always-visible desktop UI.

## 主要功能 | Features

- 普通任务：支持标题、描述、截止日期和按紧急程度排序显示。
- 周期任务：支持按周或按月重复，自动计算下一次截止日期。
- 临期提醒：支持对即将到期任务做柔和高亮，提醒强度和颜色可调。
- 自定义外观：支持纯色背景或图片背景，可调透明度、叠加层和焦点位置。
- 桌面体验：支持最小化到托盘、开机自启、关闭行为记忆等。
- 数据管理：支持任务导入、发布打包和 GitHub Release 在线更新。

- One-off tasks with title, description, deadline, and sorting by urgency.
- Recurring tasks with weekly or monthly cycles and automatic next due-date calculation.
- Due-soon highlighting with configurable overlay color and intensity.
- Custom appearance with either a solid background or an image background, including opacity, overlay, focus alignment, and drag positioning.
- Desktop-friendly behavior with tray minimization, startup launch, and remembered close actions.
- Data import plus release packaging and GitHub Release based self-update support.

## 运行环境 | Requirements

- Flutter SDK，建议安装在 `E:\flutter`
- Windows 桌面构建环境
- PowerShell，用于发布与更新脚本

- Flutter SDK, preferably installed at `E:\flutter`
- Windows desktop build toolchain
- PowerShell for release and update scripts

## 本地运行 | Local Development

```powershell
cd C:\Users\DELL\Desktop\testflt\DDLReminder
E:\flutter\bin\flutter.bat pub get
E:\flutter\bin\flutter.bat run -d windows
```

## Windows 构建 | Windows Build

调试构建：

```powershell
E:\flutter\bin\flutter.bat build windows --debug
```

发布构建：

```powershell
E:\flutter\bin\flutter.bat build windows --release
```

可运行目录位于：

```text
build\windows\x64\runner\Release
```

不要只分发单个 `exe`，需要分发整个目录。

Do not distribute only the `exe`; the whole output directory is required.

## 自动发布与更新 | Release And Update Workflow

- 版本号唯一来源：`pubspec.yaml`
- 支持通过 `scripts\bump_version.ps1` 自动递增版本号
- GitHub Release 资产名固定：`DDLReminder-windows-release.zip`
- 应用内可检查 GitHub 最新版本，并执行带回滚保护的更新脚本

- The single source of truth for versioning is `pubspec.yaml`
- Version bumping is supported through `scripts\bump_version.ps1`
- The GitHub Release asset name is fixed as `DDLReminder-windows-release.zip`
- The app can check the latest GitHub Release and run a safer updater with rollback

递增版本号：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bump_version.ps1 -Part build
```

构建发布包：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_release.ps1
```

发布到 GitHub Release：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\publish_github_release.ps1 -Bump build
```

更多规则见：

- [docs/release_management.md](docs/release_management.md)

## 项目结构 | Project Structure

```text
lib/
  core/         主题、文案、基础工具 | theme, text, utilities
  models/       数据模型 | data models
  services/     存储、更新、系统集成 | storage, update, system integration
  ui/
    dialogs/    弹窗 | dialogs
    screens/    页面 | screens
    shell/      桌面壳层 | desktop shell
    widgets/    复用组件 | reusable widgets
scripts/        构建、更新、发布脚本 | build, update, publish scripts
docs/           发布规范文档 | release documentation
```

## 说明 | Notes

- 仓库中的 `AGENTS.md` 仅用于本地代理协作，不参与 GitHub 发布内容。
- 如果修改发布资产名、更新脚本路径或目录结构，需要同步更新文档和更新服务代码。

- `AGENTS.md` is only for local agent collaboration and is intentionally excluded from GitHub.
- If you change the release asset name, updater script path, or distribution layout, update the release docs and update service together.
