@echo off
setlocal
set FLUTTER=C:\src\flutter\bin\flutter.bat
if not exist "%FLUTTER%" (
  echo Flutter SDK not found at C:\src\flutter
  exit /b 1
)
call "%FLUTTER%" pub get || exit /b 1
call "%FLUTTER%" test || exit /b 1
call "%FLUTTER%" analyze || exit /b 1
echo.
echo 3min app tests passed.
