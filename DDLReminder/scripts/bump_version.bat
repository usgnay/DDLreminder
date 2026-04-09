@echo off
setlocal

cd /d "%~dp0\.."

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0bump_version.ps1" %*

if errorlevel 1 (
  echo.
  echo [version] failed.
  pause
  exit /b %errorlevel%
)

echo.
echo [version] finished successfully.
pause
