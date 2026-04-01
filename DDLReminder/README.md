# DDLReminder

## 简介 | Overview

DDLReminder 是一个基于 Flutter 的轻量级桌面任务提醒应用，适合记录普通截止任务和周期性任务，并通过紧凑的桌面界面持续查看近期安排。

DDLReminder is a lightweight desktop task reminder built with Flutter. It helps you manage one-off deadlines and recurring tasks in a compact always-visible desktop UI.

## 主要功能 | Features

- 普通任务：设置标题、描述、截止日期，并按剩余时间排序显示。
- 周期任务：支持按周或按月重复，自动计算下一次周期日。
- 临期提醒：支持对临近到期任务做柔和遮罩提示，提醒强度和颜色可调。
- 自定义外观：支持背景色或背景图二选一，支持透明度、蒙版、焦点位置和拖拽调节。
- 桌面体验：支持窗口置顶、托盘最小化、自启动、关闭行为记忆。
- 数据管理：支持任务导入、发布打包、GitHub Release 在线更新。

- One-off tasks with title, description, deadline, and sorting by urgency.
- Recurring tasks with weekly or monthly cycles and automatic next due-date calculation.
- Due-soon highlighting with configurable overlay color and intensity.
- Custom appearance with either a solid background or an image background, including opacity, overlay, focus alignment, and drag positioning.
- Desktop-friendly behavior with tray minimization, startup launch, always-on-top support, and remembered close actions.
- Data import plus release packaging and GitHub Release based self-update support.

## 运行环境 | Requirements

- Flutter SDK：建议使用 `E:\flutter`
- Windows 桌面构建环境
- PowerShell（用于发布和更新脚本）

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

生成的一整套可运行目录位于：

The runnable output directory is:

```text
build\windows\x64\runner\Release
```

注意不要只复制单个 `exe`，需要整个目录一起分发。

Do not distribute only the `exe`; the whole output directory is required.

## 自动发布与更新 | Release And Update Workflow

- 版本号唯一来源：`pubspec.yaml`
- GitHub Release 资产名固定：`DDLReminder-windows-release.zip`
- 应用内可检查 GitHub 最新版本并执行更新脚本

- The single source of truth for versioning is `pubspec.yaml`
- The GitHub Release asset name is fixed as `DDLReminder-windows-release.zip`
- The app can check the latest GitHub Release and run the updater script

构建发布包：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_release.ps1
```

发布到 GitHub Release：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\publish_github_release.ps1
```

更多规则见：

See also:

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
- 如果更改发布资产名、更新脚本路径或目录结构，需要同步更新发布文档和更新服务代码。

- `AGENTS.md` is only for local agent collaboration and is intentionally excluded from GitHub.
- If you change the release asset name, updater script path, or distribution layout, update the release docs and update service together.
