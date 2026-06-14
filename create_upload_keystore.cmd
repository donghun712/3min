@echo off
setlocal
set KEYSTORE=android\app\upload-keystore.jks
set ALIAS=upload

if exist "%KEYSTORE%" (
  echo Upload keystore already exists: %KEYSTORE%
  echo Keep it safe. Do not overwrite it unless you intentionally want a new Play upload key.
  exit /b 1
)

where keytool >nul 2>nul
if errorlevel 1 (
  echo keytool was not found in PATH.
  echo Install or locate a JDK, then run this command manually:
  echo keytool -genkeypair -v -keystore %KEYSTORE% -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias %ALIAS%
  exit /b 1
)

echo Creating Play upload keystore:
echo %KEYSTORE%
echo.
echo You will be asked for passwords and certificate information.
echo Remember the passwords. Losing this file or password can block future app updates.
echo.
keytool -genkeypair -v -keystore "%KEYSTORE%" -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias "%ALIAS%"
if errorlevel 1 exit /b 1

echo.
echo Keystore created.
echo Now create android\key.properties using android\key.properties.example.
