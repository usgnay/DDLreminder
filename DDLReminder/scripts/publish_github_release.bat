@echo off
setlocal

cd /d "%~dp0\.."

set "DDLREMINDER_RELEASE_NOTES="
set "DDLREMINDER_GITHUB_TOKEN="
set "DDLREMINDER_BUMP_PART=build"

echo [publish] Enter bump type: build / patch / minor / major. Press Enter to use build.
set /p "DDLREMINDER_BUMP_PART=> "
if "%DDLREMINDER_BUMP_PART%"=="" set "DDLREMINDER_BUMP_PART=build"
echo.
echo [publish] Enter release notes/message. Press Enter to use the default message.
set /p "DDLREMINDER_RELEASE_NOTES=> "
echo.
echo [publish] Enter GitHub token if needed. Leave blank to use gh/GITHUB_TOKEN/GH_TOKEN.
set /p "DDLREMINDER_GITHUB_TOKEN=> "
echo.

echo [publish] starting GitHub release publish...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish_github_release.ps1" -AutoCommitDirty -Bump %DDLREMINDER_BUMP_PART%

if errorlevel 1 (
  echo.
  echo [publish] failed.
  pause
  exit /b %errorlevel%
)

echo.
echo [publish] finished successfully.
pause
