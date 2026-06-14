@echo off
setlocal
set FLUTTER=C:\src\flutter\bin\flutter.bat
if not exist "%FLUTTER%" (
  echo Flutter SDK not found at C:\src\flutter
  exit /b 1
)
call "%FLUTTER%" emulators --launch Pixel_2_API_34
