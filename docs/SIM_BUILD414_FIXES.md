# Build 414 — 전체 시뮬레이션 후속 수정 (launch-readiness-build411)

브랜치 `launch-readiness-build411` (Build 411-413 + Auth 마이그레이션 Phase 2) 에 대해
33-에이전트 시뮬레이션 워크플로우 실행 → 25 보고 → 적대적 검증 통과 20 확정.
**출시 차단(P0) = 0** (현행 빌드되는 바이너리는 OFF 플래그·미배포 룰·미주입 URL 뒤에 전부 격리).

아래는 그중 **flag-gated 라 현행 출시 빌드엔 무영향** 이지만, relay 배포 / Auth Phase 3
cutover 시점에 현실화되는 결함들을 미리 제거한 수정 내역과, 코드만으로는 닫을 수 없어
백로그로 넘긴 항목이다.

## 수정 완료 (이 커밋)

| ID | 심각도 | 내용 | 파일 |
|----|--------|------|------|
| P1-A | P1 | relay `CODE_RE`(영숫자 4-10)가 임시비번(12자+`!@#%`)을 항상 거부 → 비밀번호 찾기 메일 발송 100% 실패. type별 검증으로 분리(`OTP_RE` / `TEMP_PW_RE`). | `functions/index.js` |
| P1-B (부분) | P1 | 비번 변경 후 Firebase Auth 비번 desync → Phase 3 owner-check 403. `changePassword`(accounts:update) 추가 + `updatePassword` 에서 flag-gated best-effort 동기화. **단, 비밀번호 찾기(임시비번) 흐름은 정식 세션이 없어 미커버 → 아래 백로그.** | `firebase_auth_service.dart`, `auth_service.dart` |
| P2 | P2 | relay 미설정 release 에서 "이메일 발송됨" 거짓 안내 + 임시비번 미전달(사실상 잠금). `EmailService.isConfigured` false 면 debug 와 동일하게 화면에 임시비번 노출(fallback). | `auth_screen.dart` |
| P2 | P2 | EU/EEA 가입자(`_minAge=16`) 연령 동의 거부 에러가 '14세' 고정. `authMustAgreeAge(int age)` 로 파라미터화. | `app_localizations.dart`, `auth_screen.dart` |
| P2 | P2 | GDPR Art.20 export 가 동의 타임스탬프를 SharedPreferences 에서(+2건 잘못된 키로) 읽어 항상 null. `FlutterSecureStorage` + 정확한 키(`consent_age_above14_ts`/`consent_third_party_sharing_ts`)로 정정. | `settings_screen.dart` |
| P2 | P2 | `.env.example` 가 폐기된 RESEND/SENDGRID 키 안내. `AUTH_EMAIL_FN_URL`/`AUTH_SMS_FN_URL` + 시크릿 등록 절차로 교체. | `.env.example` |

검증: `flutter analyze` 클린 · 137 테스트 통과 · `node --check functions/index.js` OK.

## 백로그 (코드 단독 수정 불가 / Phase 3 / 운영)

- **P1-B 잔여 — 비밀번호 찾기(임시비번) 흐름의 Firebase desync.** 사용자가 비번을
  잊은 경우 임시비번 로그인 시점에 정식 Firebase 세션이 없어 클라이언트가
  accounts:update 로 동기화 불가. 올바른 해법은 서버측 reset(Cloud Function +
  Admin SDK `updateUser`, 또는 Firebase 이메일 기반 password reset). **Phase 3 선결.**
- **P1-C — `brand_zones` redemptionCode world-readable + adminFetch 무인증.** 이 브랜치
  회귀 아님(기존 deferred 백로그 ③). rules 변경이 아니라 Auth Phase 2/3 + subcollection
  분리 / server-side 코드 issuance 백엔드 작업 필요.
- **현행 룰 `authUid` owner-check 가드 부재** — Phase 3 cutover 시 `isAuthUidBindSafe`
  (firestore.rules.phase2) 적용 + 기존 authUid 재검증 가드 필요. 현재는 additive 라 무해.
- **restore/refresh 정합성(P2)** — `restoreRealSessionIfAvailable` 가 `_uid` 미설정,
  refresh 영구 실패 후 anon fallback 부재. Phase 3 활성화 전 묶어서 처리.
- **P3 잔여** — SMS 실패 메시지 4언어→14언어, signUp WEAK_PASSWORD "6자" vs 앱 8자 문구,
  SecureClipboard 미만료 kill-swipe 잔존, '전체 동의' 카드 마케팅 항목 안내, 마케팅 동의
  in-app opt-out 토글(발송 로직 0건이라 실질 피해 없음).

## 코드 외 잔존 BLOCKER (출시 전 운영 필수, 이 리포트 범위 밖)

- Resend/Twilio 키 rotate + `functions/` 배포(Blaze) + `functions:secrets` 등록 +
  함수 URL 빌드 주입 — **이때 P1-A 수정본이 적용돼야 비밀번호 찾기 정상 동작.**
- 방통위 위치기반서비스사업 신고(emsit.go.kr)
- privacy/terms/location_terms thiscount.io 호스팅(in-app 링크 현재 404)
- 서버 letters hard-delete Cloud Function(GDPR Art.17)
- App Store Privacy Label / Play Data Safety 폼
