# LetterGo 실기기 결제 QA 리포트 (1차)

Date: 2026-04-02  
기준 체크리스트: `docs/release/real-device-purchase-qa-checklist.md`

## 1) 자동 검증 결과 (이번 실행)

| 항목 | 결과 | 근거 |
|---|---|---|
| Release preflight | PASS | `./scripts/release_preflight.sh` 통과 |
| Flutter analyze | PASS | 이슈 0건 |
| Flutter test | PASS | `App smoke test` 통과 |
| Android release build | PASS | `build/app/outputs/flutter-apk/app-release.apk` 생성 |
| iOS release build (no-codesign) | PASS | `build/ios/iphoneos/Runner.app` 생성 |
| Security audit | PASS (WARN 있음) | 민감 파일 로컬 존재 경고 (`google-services.json`, `GoogleService-Info.plist`) |

## 2) 결제/복원 실기기 시나리오 결과 (1차)

주의:
- 아래 항목은 **Codex 환경에서 스토어 결제 시트를 직접 조작할 수 없어** 실기기 수동 검증이 필요합니다.
- 현재는 상태를 `확인 필요`로 기록합니다.

| 항목 | iOS | Android | 비고 |
|---|---|---|---|
| 상품 노출 | 확인 필요 | 확인 필요 | 구독 화면 진입 후 상품 카드/가격 확인 필요 |
| Premium 구매 | 확인 필요 | 확인 필요 | 스토어 결제 승인 후 entitlement 반영 확인 |
| Brand 구매 | 확인 필요 | 확인 필요 | Premium 포함/Brand 전용 UI 반영 확인 |
| 선물권 구매 | 확인 필요 | 확인 필요 | 코드 생성/공유 UI 확인 |
| 추가 발송권 구매 | 확인 필요 | 확인 필요 | 중복 지급 방지(transactionId idempotency) 확인 |
| 구매 복원 | 확인 필요 | 확인 필요 | iOS Apple 로그인 팝업 정상 여부 포함 |
| 플랜 변경 정책 | 확인 필요 | 확인 필요 | 다음 결제일 반영/다운그레이드 제약 확인 |
| 결제 후 회귀 기능 | 확인 필요 | 확인 필요 | 한도/권한/재로그인 후 유지 확인 |

## 3) 배포 전 남은 필수 확인

1. iOS Sandbox 계정으로 `Premium/Brand/Gift/Restore` 4개 시나리오 PASS 획득
2. Android Internal Testing(또는 License Tester)에서 동일 4개 시나리오 PASS 획득
3. Brand 추가발송권 구매 후 월간 쿼터 증가 및 중복 구매 방지 확인
4. `.env.local` 키 로테이션 및 vault 보관 확인

## 4) 판정

- 현재 판정: **조건부 보류**
- 사유: 자동 검증은 모두 통과했으나, 스토어 실결제 시나리오 PASS 증적이 아직 없음
