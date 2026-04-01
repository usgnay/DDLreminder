@echo off
setlocal

cd /d "%~dp0\.."

echo [build] starting Windows release packaging...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_release.ps1"

if errorlevel 1 (
  echo.
  echo [build] failed.
  pause
  exit /b %errorlevel%
)

echo.
echo [build] finished successfully.
pause
