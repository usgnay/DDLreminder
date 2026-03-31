#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <memory>

#include "win32_window.h"

class FlutterWindow : public Win32Window {
 public:
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  void InitializeSystemTray();
  void RemoveSystemTray();
  void ShowSystemTrayBalloon(const std::wstring& title, const std::wstring& body);
  void ShowContextMenu();
  void RestoreFromTray();
  void ExitFromTray();
  void RegisterMethodChannel();

  flutter::DartProject project_;
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
  NOTIFYICONDATA tray_icon_data_{};
  bool tray_initialized_ = false;
  bool suppress_close_to_tray_ = false;
  bool close_tip_shown_ = false;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
