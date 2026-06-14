# Play Store 업로드 키 생성 가이드

Android 앱을 Play Store에 올리려면 release AAB가 업로드 키로 서명되어야 합니다. 이 키는 앱 업데이트에 계속 필요하므로 절대 잃어버리면 안 됩니다.

## 1. 업로드 키 만들기

저장소 루트에서 실행합니다.

```powershell
.\create_upload_keystore.cmd
```

스크립트는 아래 파일을 만듭니다.

```text
android\app\upload-keystore.jks
```

실행 중 입력하는 비밀번호는 반드시 따로 안전하게 보관하세요.

## 2. key.properties 만들기

`android\key.properties.example`을 복사해서 `android\key.properties`를 만듭니다.

```properties
storePassword=위에서 입력한 keystore 비밀번호
keyPassword=위에서 입력한 key 비밀번호
keyAlias=upload
storeFile=app/upload-keystore.jks
```

`android\key.properties`와 `android\app\upload-keystore.jks`는 `.gitignore`에 들어가 있으므로 GitHub에 올리지 않습니다.

## 3. 정식 release AAB 빌드

```powershell
.\build_release.cmd
```

결과 파일:

```text
build\app\outputs\bundle\release\app-release.aab
```

이 파일을 Play Console 내부 테스트 또는 프로덕션 릴리즈에 업로드합니다.

## 주의

- upload keystore 파일과 비밀번호를 잃어버리지 마세요.
- 이미 Play Console에 앱을 등록한 뒤에는 Application ID `com.threeminmeals.app`을 바꾸면 안 됩니다.
- Google Play App Signing을 켜면 Google이 앱 서명 키를 관리하고, 개발자는 upload key로 업로드합니다.
