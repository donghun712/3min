# 3분세끼

3분세끼는 오늘 먹을 메뉴를 빠르게 고를 수 있도록 돕는 Flutter Android 앱입니다.
서버 없이 동작하며, 메뉴 데이터와 사용자 설정, 추천 기록은 기기 내부에서 처리합니다.

## 현재 구현 범위

- 최초 실행 온보딩
- 못 먹는 음식 태그 설정 및 초기화
- 한식, 중식, 일식, 양식, 기타 메뉴 데이터 기반 추천
- 가격대와 카테고리를 반영한 메뉴 추천
- 카드 스와이프 기반 추천
  - 오른쪽 스와이프: 좋아요
  - 왼쪽 스와이프: 싫어요
  - 카드별 제한 시간 경과 시 자동 전환
- 좋아요 메뉴 기반 추천 조합 생성
- 순수 랜덤 추천 페이지
- 최근 식사 기록 저장 및 수정
- 로컬 저장소 기반 설정 유지
- 앱 아이콘, Play Store 그래픽 이미지, 휴대폰/태블릿 스크린샷 준비

현재 버전에는 실제 광고 SDK가 포함되어 있지 않습니다.
AdMob 등 광고 수익화는 정식 출시 이후 별도 업데이트로 추가할 예정입니다.

## Android 정보

- 앱 이름: `3분세끼`
- Application ID: `com.threeminmeals.app`
- Version: `1.0.0+2`
- 앱 아이콘: `assets/store/icon-512.png`
- 그래픽 이미지: `assets/store/feature-graphic.png`
- 개인정보처리방침: `https://donghun712.github.io/3min/privacy_policy.html`

## 테스트

저장소 루트에서 실행합니다.

```powershell
.\test_app.cmd
```

직접 Flutter 명령을 사용할 수도 있습니다.

```powershell
flutter analyze
flutter test
```

## 실행

에뮬레이터를 실행한 뒤 앱을 실행합니다.

```powershell
.\start_android_emulator.cmd
.\run_app.cmd
```

이미 APK가 만들어져 있다면 직접 설치/실행할 수도 있습니다.

```powershell
C:\Users\nkehd\AppData\Local\Android\Sdk\platform-tools\adb.exe -s emulator-5554 install -r build\app\outputs\flutter-apk\app-debug.apk
C:\Users\nkehd\AppData\Local\Android\Sdk\platform-tools\adb.exe -s emulator-5554 shell monkey -p com.threeminmeals.app -c android.intent.category.LAUNCHER 1
```

## 릴리즈 빌드

Play Store 업로드용 AAB를 생성합니다.

```powershell
.\build_release.cmd
```

출력 경로:

```text
build\app\outputs\bundle\release\app-release.aab
```

정식 업로드 전에는 `android/key.properties`와 upload keystore가 필요합니다.
처음 설정하거나 비밀번호가 꼬였을 때는 아래 스크립트를 사용할 수 있습니다.

```powershell
powershell -ExecutionPolicy Bypass -File .\reset_upload_signing.ps1
```

기존 키스토어를 유지하고 `android/key.properties`만 다시 만들 때는 아래 스크립트를 사용합니다.

```powershell
.\configure_upload_key.cmd
```

자세한 내용은 [Play Store 업로드 서명 키 생성 가이드](docs/upload_key_guide.md)를 참고하세요.

## Play Store 준비 파일

- 앱 아이콘: `assets/store/icon-512.png`
- 그래픽 이미지: `assets/store/feature-graphic.png`
- 휴대폰 스크린샷: `assets/store/screenshot-01.png`
- 7인치 태블릿 스크린샷: `assets/store/tablet-7-screenshot-01.png`
- 10인치 태블릿 스크린샷: `assets/store/tablet-10-screenshot-01.png`

## 문서

- [개인정보처리방침 Markdown](docs/privacy_policy.md)
- [개인정보처리방침 HTML](docs/privacy_policy.html)
- [Play Store 등록 문구](docs/play_store_listing.md)
- [릴리즈 체크리스트](docs/release_checklist.md)
- [업로드 키 생성 가이드](docs/upload_key_guide.md)

## Git에 올리면 안 되는 파일

아래 파일은 서명키 또는 로컬 설정이므로 GitHub에 올리지 않습니다.

```text
android/key.properties
android/key.properties.bak-*
android/app/upload-keystore.jks
android/app/upload-keystore.jks.bak-*
*.jks
```

`.gitignore`와 `android/.gitignore`에 등록되어 있습니다.
