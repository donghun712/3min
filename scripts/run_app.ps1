$ErrorActionPreference = "Stop"

$flutter = "C:\src\flutter\bin\flutter.bat"
if (-not (Test-Path $flutter)) {
  throw "Flutter SDK를 C:\src\flutter 에서 찾지 못했습니다."
}

& $flutter pub get
& $flutter run
