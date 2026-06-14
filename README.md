# 3분세끼

서버 없이 동작하는 Android 전용 Flutter 로컬 앱입니다. 메뉴 데이터, 설정, 추천 결과, 식사 기록을 모두 기기 안에서 처리합니다.

## 현재 구현 범위

- 최초 실행 온보딩과 못먹는 음식 태그 조사
- 설정 탭에서 못먹는 음식 태그 변경 및 앱 데이터 초기화
- 한식/중식/양식/일식/기타 총 283개 로컬 메뉴 데이터
- 가격대, 대분류, 중분류 기반 추천
- 카드 스와이프 추천
  - 오른쪽 스와이프: 좋아요
  - 왼쪽 스와이프: 싫어요
  - 카드별 10초 제한 및 시간 초과 자동 탈락
- 좋아요 메뉴 기반 토너먼트
- 와일드카드/부전승 보정
- 가격만 고르는 순수 랜덤 추천 탭
- 최근 10회 식사 기록과 직접 수정
- 하단 AdMob 배너 영역 플레이스홀더
- 핵심 로직 및 데이터 품질 회귀 테스트

## Android 정보

- 앱 이름: `3분세끼`
- Application ID: `com.threeminmeals.app`
- Version: `1.0.0+1`
- 아이콘: `assets/store/icon-512.png`

## 테스트

이 PC에서는 저장소 루트에서 아래 배치 파일을 쓰면 PATH 문제 없이 테스트할 수 있습니다.

```powershell
.\test_app.cmd
```

직접 Flutter 명령을 쓸 수 있는 환경이라면:

```powershell
flutter test
flutter analyze
```

## 실행

에뮬레이터를 켠 뒤 앱을 실행합니다.

```powershell
.\start_android_emulator.cmd
.\run_app.cmd
```

이미 APK가 만들어져 있다면 직접 설치/실행할 수도 있습니다.

```powershell
C:\Users\nkehd\AppData\Local\Android\sdk\platform-tools\adb.exe -s emulator-5554 install -r build\app\outputs\flutter-apk\app-debug.apk
C:\Users\nkehd\AppData\Local\Android\sdk\platform-tools\adb.exe -s emulator-5554 shell monkey -p com.threeminmeals.app -c android.intent.category.LAUNCHER 1
```

## 릴리즈 빌드

Play Store 업로드용 AAB는 아래 명령으로 만듭니다.

```powershell
.\build_release.cmd
```

출력 경로:

```text
build\app\outputs\bundle\release\app-release.aab
```

정식 업로드 전에는 `android/key.properties`와 upload keystore를 준비해야 합니다. 예시는 [android/key.properties.example](android/key.properties.example)를 참고하세요.
자세한 절차는 [업로드 키 생성 가이드](docs/upload_key_guide.md)를 참고하세요.

키를 이미 만들었다면, 아래 스크립트로 `android/key.properties`를 생성할 수 있습니다.

```powershell
.\configure_upload_key.cmd
```

## 스토어 준비 문서

- [개인정보처리방침 초안](docs/privacy_policy.md)
- [Play Store 등록 문구 초안](docs/play_store_listing.md)
- [릴리즈 체크리스트](docs/release_checklist.md)
- [업로드 키 생성 가이드](docs/upload_key_guide.md)

사진은 1차 출시에서는 사용하지 않습니다. 추후 `assets/data/menuData.json`의 `image_path`를 채우고 `pubspec.yaml`에 이미지 에셋 경로를 추가하면 됩니다.
