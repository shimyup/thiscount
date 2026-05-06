# Reviewer Checklist

## 1) 릴리즈 안정성

- [ ] `scripts/release_preflight.sh` 로컬 실행 시 PASS 확인
- [ ] `scripts/build_android_release.sh` 산출물 생성 확인
- [ ] `scripts/build_ios_release.sh` 산출물 생성 확인(no-codesign)

## 2) 보안/비밀키 운영

- [ ] `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`가 Git에 추적되지 않는지 확인
- [ ] `scripts/manage_firebase_secrets.sh restore/store` 동작 확인
- [ ] `scripts/security_audit.sh` PASS 확인

## 3) 앱 동작/회귀

- [ ] iOS 시뮬레이터에서 앱 실행 확인
- [ ] Android 에뮬레이터에서 앱 실행 확인
- [ ] 로그인/회원가입/편지 작성/지도/인박스 기본 플로우 회귀 체크
- [ ] 구독 화면 진입 및 상품 로딩 확인

## 4) 스토어 제출물

- [ ] `docs/marketing/screenshots/ready/ios67` 해상도 확인(1290x2796)
- [ ] `docs/marketing/screenshots/ready/ios65` 해상도 확인(1284x2778)
- [ ] `docs/marketing/creative-kit/exports/play-feature-graphic-1024x500.png` 확인
- [ ] `docs/release/app-store-connect-paste-ready.md` 연락처/문구 최종값 확인

## 5) 정책/문구

- [ ] 지원 이메일이 `ceo@airony.xyz`로 일관된지 확인
- [ ] 앱 타이틀 표기(`Thiscount`) 확인
- [ ] 읽음 편지 30일 정리 로직 반영 여부 확인
