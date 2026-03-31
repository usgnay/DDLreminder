#include "flutter_window.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <shellapi.h>

#include <optional>
#include <vector>

#include "flutter/generated_plugin_registrant.h"
#include "resource.h"

namespace {
constexpr UINT kTrayMessage = WM_APP + 1;
constexpr UINT kTrayIconId = 1001;
constexpr UINT kMenuShowId = 2001;
constexpr UINT kMenuExitId = 2002;

std::wstring Utf8ToWide(const std::string& text) {
  if (text.empty()) {
    return L"";
  }
  const int size = MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, nullptr, 0);
  if (size <= 0) {
    return L"";
  }
  std::wstring result(size, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, result.data(), size);
  result.resize(size - 1);
  return result;
}
}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project) : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }

  RegisterPlugins(flutter_controller_->engine());
  RegisterMethodChannel();
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  InitializeSystemTray();

  flutter_controller_->engine()->SetNextFrameCallback([&]() { this->Show(); });
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  RemoveSystemTray();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT FlutterWindow::MessageHandler(HWND hwnd,
                                      UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam, lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_CLOSE:
      if (!suppress_close_to_tray_) {
        ShowWindow(hwnd, SW_HIDE);
        if (!close_tip_shown_) {
          ShowSystemTrayBalloon(
              L"DDLreminder",
              L"Minimized to tray. Right-click the tray icon to show or exit.");
          close_tip_shown_ = true;
        }
        return 0;
      }
      break;
    case kTrayMessage:
      switch (LOWORD(lparam)) {
        case WM_LBUTTONUP:
        case WM_LBUTTONDBLCLK:
          RestoreFromTray();
          return 0;
        case WM_RBUTTONUP:
          ShowContextMenu();
          return 0;
      }
      break;
    case WM_COMMAND:
      switch (LOWORD(wparam)) {
        case kMenuShowId:
          RestoreFromTray();
          return 0;
        case kMenuExitId:
          ExitFromTray();
          return 0;
      }
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::InitializeSystemTray() {
  if (tray_initialized_) {
    return;
  }

  tray_icon_data_.cbSize = sizeof(NOTIFYICONDATA);
  tray_icon_data_.hWnd = GetHandle();
  tray_icon_data_.uID = kTrayIconId;
  tray_icon_data_.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
  tray_icon_data_.uCallbackMessage = kTrayMessage;
  tray_icon_data_.hIcon = LoadIcon(GetModuleHandle(nullptr), MAKEINTRESOURCE(IDI_APP_ICON));
  wcscpy_s(tray_icon_data_.szTip, L"DDLreminder");

  tray_initialized_ = Shell_NotifyIcon(NIM_ADD, &tray_icon_data_) == TRUE;
}

void FlutterWindow::RemoveSystemTray() {
  if (!tray_initialized_) {
    return;
  }
  Shell_NotifyIcon(NIM_DELETE, &tray_icon_data_);
  tray_initialized_ = false;
}

void FlutterWindow::ShowSystemTrayBalloon(const std::wstring& title,
                                          const std::wstring& body) {
  if (!tray_initialized_) {
    return;
  }

  NOTIFYICONDATA data = tray_icon_data_;
  data.uFlags = NIF_INFO;
  wcscpy_s(data.szInfoTitle, title.c_str());
  wcscpy_s(data.szInfo, body.c_str());
  data.dwInfoFlags = NIIF_INFO;
  Shell_NotifyIcon(NIM_MODIFY, &data);
}

void FlutterWindow::ShowContextMenu() {
  POINT cursor_pos;
  GetCursorPos(&cursor_pos);

  HMENU menu = CreatePopupMenu();
  AppendMenu(menu, MF_STRING, kMenuShowId, L"Show");
  AppendMenu(menu, MF_STRING, kMenuExitId, L"Exit");

  SetForegroundWindow(GetHandle());
  TrackPopupMenu(menu, TPM_RIGHTBUTTON, cursor_pos.x, cursor_pos.y, 0, GetHandle(), nullptr);
  DestroyMenu(menu);
}

void FlutterWindow::RestoreFromTray() {
  ShowWindow(GetHandle(), SW_SHOW);
  SetForegroundWindow(GetHandle());
}

void FlutterWindow::ExitFromTray() {
  suppress_close_to_tray_ = true;
  Destroy();
  PostQuitMessage(0);
}

void FlutterWindow::RegisterMethodChannel() {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "ddlreminder/system_shell",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "showReminderNotification") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (args != nullptr) {
            const auto title_it = args->find(flutter::EncodableValue("title"));
            const auto body_it = args->find(flutter::EncodableValue("body"));
            std::wstring title = L"DDLreminder";
            std::wstring body;

            if (title_it != args->end()) {
              if (const auto* title_value = std::get_if<std::string>(&title_it->second)) {
                title = Utf8ToWide(*title_value);
              }
            }
            if (body_it != args->end()) {
              if (const auto* body_value = std::get_if<std::string>(&body_it->second)) {
                body = Utf8ToWide(*body_value);
              }
            }

            ShowSystemTrayBalloon(title, body);
          }
          result->Success();
          return;
        }

        result->NotImplemented();
      });

  static std::vector<std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>> channels;
  channels.push_back(std::move(channel));
}
