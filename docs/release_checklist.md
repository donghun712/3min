# 릴리즈 체크리스트

## 코드/빌드

- [x] Application ID를 `com.threeminmeals.app`으로 변경
- [x] 앱 표시 이름을 `3분세끼`로 변경
- [x] 버전을 `1.0.0+1`로 설정
- [x] debug/profile 실행 확인
- [x] `flutter test` 통과
- [x] `flutter analyze` 통과
- [x] release AAB 빌드 스크립트 추가
- [x] release AAB dry-run 빌드 성공
- [x] 앱 아이콘 교체
- [x] upload keystore 생성 스크립트 추가
- [ ] upload keystore 생성
- [ ] `android/key.properties` 작성
- [ ] 실제 release 서명 AAB 빌드

## 앱 품질

- [x] 메뉴 데이터 283개 정리
- [x] 해산물 등 못먹는 음식 태그 회귀 테스트 추가
- [x] 추천/랜덤/기록/설정 기본 플로우 구현
- [x] 기본 UI를 흰 배경과 밝은 카드 스타일로 정리
- [ ] 실제 Android 기기에서 1회 이상 수동 테스트
- [ ] 온보딩 초기화 후 최초 실행 플로우 최종 확인
- [ ] 낮은 가격대/강한 필터 조건에서 후보 없음 화면 확인

## Play Store

- [x] Play Store 등록 문구 초안 작성
- [x] 개인정보처리방침 초안 작성
- [ ] 개인정보처리방침 게시 URL 준비
- [ ] 스크린샷 촬영
- [ ] 피처 그래픽 제작
- [ ] 콘텐츠 등급 설문 작성
- [ ] Data Safety 작성
- [ ] 내부 테스트 트랙 업로드

## 출시 직전 주의

- 현재 광고 SDK는 실제 연동되어 있지 않고 배너 자리만 있습니다.
- AdMob을 붙이면 개인정보처리방침과 Data Safety 내용을 다시 수정해야 합니다.
- 앱 아이콘은 `assets/store/icon-512.png`와 Android mipmap 리소스에 반영되었습니다.
