@echo off
setlocal
set KEYSTORE=android\app\upload-keystore.jks
set PROPS=android\key.properties

if not exist "%KEYSTORE%" (
  echo Upload keystore was not found: %KEYSTORE%
  echo Run create_upload_keystore.cmd first.
  exit /b 1
)

if exist "%PROPS%" (
  echo %PROPS% already exists.
  echo Delete it first if you intentionally want to recreate it.
  exit /b 1
)

echo This will create %PROPS%.
echo Password input will not be hidden in this basic Windows batch prompt.
echo If you do not want the password visible, edit android\key.properties manually from android\key.properties.example instead.
echo.

set /p STOREPASS=Keystore password:
set /p KEYPASS=Key password, usually same as keystore password:

(
  echo storePassword=%STOREPASS%
  echo keyPassword=%KEYPASS%
  echo keyAlias=upload
  echo storeFile=app/upload-keystore.jks
) > "%PROPS%"

echo.
echo Created %PROPS%.
echo Now run build_release.cmd.
