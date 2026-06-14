# Play Store 업로드 서명 키 생성 가이드

Android 앱을 Play Store에 올리려면 release AAB가 업로드 키로 서명되어야 합니다.
이 키는 이후 앱 업데이트에도 계속 필요하므로 안전하게 보관해야 합니다.

## 가장 쉬운 방법

아직 Play Console에 AAB를 처음 업로드하기 전이라면 아래 스크립트 하나로 키스토어와 설정 파일을 같이 만들 수 있습니다.

```powershell
.\reset_upload_signing.ps1
```

이 스크립트는 다음 파일을 생성합니다.

```text
android\app\upload-keystore.jks
android\key.properties
```

이미 같은 파일이 있으면 `.bak-날짜` 파일로 백업한 뒤 새로 만듭니다.

## 수동 생성 방법

저장소 루트에서 실행합니다.

```powershell
.\create_upload_keystore.cmd
```

그다음 `android\key.properties.example`을 복사해서 `android\key.properties`를 만듭니다.

```properties
storePassword=위에서 입력한 keystore 비밀번호
keyPassword=위에서 입력한 key 비밀번호
keyAlias=upload
storeFile=upload-keystore.jks
```

## release AAB 빌드

```powershell
.\build_release.cmd
```

결과 파일:

```text
build\app\outputs\bundle\release\app-release.aab
```

이 파일을 Play Console의 테스트 또는 프로덕션 릴리즈에 업로드합니다.

## 주의

- `android\key.properties`와 `android\app\upload-keystore.jks`는 GitHub에 올리지 않습니다.
- upload keystore 파일과 비밀번호를 잃어버리면 이후 앱 업데이트가 어려워질 수 있습니다.
- 이미 Play Console에 첫 AAB를 업로드한 뒤에는 함부로 새 키스토어를 만들면 안 됩니다.
- Play Console 등록 이후에는 Application ID `com.threeminmeals.app`을 바꾸면 안 됩니다.
