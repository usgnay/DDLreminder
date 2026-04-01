@echo off
setlocal

cd /d "%~dp0\.."

echo [publish] starting GitHub release publish...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish_github_release.ps1" -AutoCommitDirty

if errorlevel 1 (
  echo.
  echo [publish] failed.
  pause
  exit /b %errorlevel%
)

echo.
echo [publish] finished successfully.
pause
