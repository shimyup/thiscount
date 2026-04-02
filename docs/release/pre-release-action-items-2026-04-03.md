# Letter Go 배포 전 액션 아이템 (2026-04-03)

## 1. 코드/빌드 상태

- `flutter analyze`: PASS
- `flutter test`: PASS
- `./scripts/security_audit.sh`: PASS
- `./scripts/release_preflight.sh`: FAIL (현재 Firebase 파일 vault 보관 상태)

## 2. 즉시 처리 필요 (릴리즈 직전)

1. Firebase 설정 파일 복원
2. preflight 재실행
3. iOS/Android 릴리즈 빌드
4. 실기기 결제 시나리오 재검증

### 실행 커맨드

```bash
cd '/Users/shimyup/Documents/New project/Lettergo'
./scripts/manage_firebase_secrets.sh restore
./scripts/release_preflight.sh
./scripts/build_ios_release.sh
./scripts/build_android_release.sh
```

## 3. 스토어 제출 전 체크

1. App Store Connect
- 부제목: `세계로 보내는 랜덤 편지`
- Review Contact 전화번호를 실사용 번호로 교체
- Privacy/Support/Terms URL 실제 배포 도메인 연결 확인

2. Google Play Console
- Data safety 체크박스 입력값 재검토
- Feature Graphic 업로드 (`1024x500`)
- 폰 스크린샷 최소 2장 이상 업로드

## 4. 운영/보안 체크

1. `.env.local`의 키가 placeholder가 아닌지 점검
2. `google-services.json`, `GoogleService-Info.plist`를 Git에 포함하지 않기
3. 배포 후 `./scripts/manage_firebase_secrets.sh store`로 vault 재이관
