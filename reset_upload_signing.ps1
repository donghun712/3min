$ErrorActionPreference = "Stop"

$keystorePath = Join-Path $PSScriptRoot "android\app\upload-keystore.jks"
$propsPath = Join-Path $PSScriptRoot "android\key.properties"
$keytool = "keytool"

if (-not (Get-Command $keytool -ErrorAction SilentlyContinue)) {
  $jdkKeytool = "C:\Program Files\Eclipse Adoptium\jdk-17.0.17.10-hotspot\bin\keytool.exe"
  if (Test-Path $jdkKeytool) {
    $keytool = $jdkKeytool
  } else {
    Write-Error "keytool was not found. Install a JDK or add keytool to PATH."
  }
}

Write-Host "This will recreate the local Play upload signing key and android\key.properties."
Write-Host "Use this only before the first Play Console upload, or when you intentionally want a new upload key."
Write-Host ""

$confirm = Read-Host "Continue? Type YES"
if ($confirm -ne "YES") {
  Write-Host "Canceled."
  exit 1
}

$password = Read-Host "New keystore/key password" -AsSecureString
$passwordAgain = Read-Host "Repeat password" -AsSecureString

$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
$bstrAgain = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordAgain)
try {
  $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  $plainPasswordAgain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstrAgain)
} finally {
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstrAgain)
}

if ([string]::IsNullOrWhiteSpace($plainPassword)) {
  Write-Error "Password cannot be empty."
}

if ($plainPassword -ne $plainPasswordAgain) {
  Write-Error "Passwords do not match."
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
if (Test-Path $keystorePath) {
  Move-Item -LiteralPath $keystorePath -Destination "$keystorePath.bak-$timestamp"
}
if (Test-Path $propsPath) {
  Move-Item -LiteralPath $propsPath -Destination "$propsPath.bak-$timestamp"
}

& $keytool `
  -genkeypair `
  -v `
  -keystore $keystorePath `
  -storetype JKS `
  -storepass $plainPassword `
  -keypass $plainPassword `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias upload `
  -dname "CN=Kim DongHun, OU=student, O=Jbnu, L=Jeonju-si, ST=Jeollabuk-do, C=KR"

if ($LASTEXITCODE -ne 0) {
  Write-Error "keytool failed with exit code $LASTEXITCODE."
}

@(
  "storePassword=$plainPassword"
  "keyPassword=$plainPassword"
  "keyAlias=upload"
  "storeFile=upload-keystore.jks"
) | Set-Content -LiteralPath $propsPath -Encoding ASCII

Write-Host ""
Write-Host "Upload signing key and android\key.properties were recreated."
Write-Host "Now run: .\build_release.cmd"
