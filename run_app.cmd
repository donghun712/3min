@echo off
setlocal
set FLUTTER=C:\src\flutter\bin\flutter.bat
set ADB=C:\Users\nkehd\AppData\Local\Android\sdk\platform-tools\adb.exe
set APK=build\app\outputs\flutter-apk\app-debug.apk
if not exist "%FLUTTER%" (
  echo Flutter SDK not found at C:\src\flutter
  exit /b 1
)
if not exist "%ADB%" (
  echo adb.exe not found in Android SDK platform-tools.
  exit /b 1
)
call "%FLUTTER%" pub get || exit /b 1
pushd android
call gradlew.bat :app:assembleDebug --console=plain || exit /b 1
popd
if not exist "%APK%" (
  echo APK was not created: %APK%
  exit /b 1
)
call "%ADB%" -s emulator-5554 install -r "%APK%" || exit /b 1
call "%ADB%" -s emulator-5554 shell monkey -p com.threeminmeals.app -c android.intent.category.LAUNCHER 1
