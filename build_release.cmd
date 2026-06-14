@echo off
setlocal
set FLUTTER=C:\src\flutter\bin\flutter.bat
if not exist "%FLUTTER%" (
  echo Flutter SDK not found at C:\src\flutter
  exit /b 1
)
if not exist "android\key.properties" (
  echo.
  echo WARNING: android\key.properties was not found.
  echo The release bundle will use the debug signing fallback and is not suitable for Play Store upload.
  echo Create android\key.properties from android\key.properties.example before final upload.
  echo.
)
call "%FLUTTER%" pub get || exit /b 1
call "%FLUTTER%" build appbundle --release || exit /b 1
echo.
echo Release bundle:
echo build\app\outputs\bundle\release\app-release.aab
