$FlutterBat = "E:\flutter\bin\flutter.bat"

if (-not (Test-Path $FlutterBat)) {
    Write-Error "Flutter SDK not found at $FlutterBat"
    exit 1
}

& $FlutterBat @args
exit $LASTEXITCODE
