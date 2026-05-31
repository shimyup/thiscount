# Thiscount Auth Relay Functions

이메일/SMS 인증 발송을 서버에서 처리하는 Cloud Function. **서버급 API 키
(Resend/Twilio)를 클라이언트 바이너리에서 제거하기 위한 보안 필수 구성요소**
(Build 412 — PII 시뮬레이션 CRITICAL fix).

## 왜 필요한가
이전엔 Resend/Twilio 키를 `--dart-define` 으로 앱에 컴파일 → 공격자가 IPA/APK 를
`strings` 로 긁어 키를 추출 → 검증된 도메인(thiscount.io)으로 위장 메일 발송
(피싱) → 계정 탈취가 가능했습니다. 이 함수가 키를 서버에만 두고, **인증된**
(Firebase ID 토큰) 호출자에게 **고정 템플릿** OTP/임시비밀번호만 발송합니다.

## 함수
- `sendAuthEmail` — `{type: 'otp'|'tempPassword', to, code, expiresInMinutes?, langCode}`
- `sendAuthSms` — `{to, code, langCode}`
둘 다 `Authorization: Bearer <Firebase ID 토큰>` 필수, per-uid 분당 5회 rate limit,
입력 형식 검증(이메일/전화/코드), 본문은 서버 템플릿으로만 생성.

## 배포 (1회 셋업)
```bash
cd functions
npm install

# 시크릿 등록 (값 입력 프롬프트):
firebase functions:secrets:set RESEND_API_KEY        # 새로 발급한 Resend 키
firebase functions:secrets:set TWILIO_ACCOUNT_SID    # (SMS 사용 시)
firebase functions:secrets:set TWILIO_AUTH_TOKEN     # (SMS 사용 시)

# 발신번호(비밀 아님)는 환경변수로 (SMS 사용 시):
#   functions/.env 에  TWILIO_FROM_NUMBER=+1xxxxxxxxxx

firebase deploy --only functions
```
> ⚠️ 아웃바운드 네트워크(Resend/Twilio) 호출은 Firebase **Blaze(종량제)** 플랜 필요.

## 배포 후
배포 출력의 함수 URL 을 클라이언트 빌드 환경(.env.local)에 넣으면 실제 발송이 켜집니다:
```
AUTH_EMAIL_FN_URL=https://us-central1-<project>.cloudfunctions.net/sendAuthEmail
AUTH_SMS_FN_URL=https://us-central1-<project>.cloudfunctions.net/sendAuthSms
```
URL 미설정 시 클라이언트는 발송을 스킵하고 **on-screen OTP fallback** 으로 동작
(개발/미배포 단계에서 흐름 유지).

## 보안 메모
- 이전 키 `re_MBwa…` 는 ≤Build 410 빌드에 이미 나갔으므로 **반드시 폐기/재발급**.
- 클라이언트는 함수 URL(공개 가능)만 알며, 키는 절대 바이너리에 들어가지 않음.
- 함수는 임의 본문을 받지 않음(템플릿 고정) → 도메인 사칭 발송 차단.

## revenueCatWebhook — 결제 크레딧 서버 권위 grant (sim200 P0-A 근본 해결)
ExactDrop/추가발송권 크레딧 **증가**는 firestore.rules(self-mint 차단, 감소만 허용)
때문에 client 가 쓸 수 없다. 이 webhook 이 RevenueCat 결제 이벤트를 받아 Admin SDK
(룰 우회)로 `users/{app_user_id}` 의 크레딧을 원자적·멱등(event.id dedup)으로 증가시킨다.
client 는 다음 동기화에서 `_restoreProfileFromServer` 의 가산형 복원(server>local 채택)으로
서버 grant 값을 흡수한다 → 재설치/기변에도 유료 자산 보존.

```bash
# 1) webhook 인증용 비밀(임의의 긴 무작위 문자열) 등록
firebase functions:secrets:set RC_WEBHOOK_AUTH
# 2) 배포
firebase deploy --only functions:revenueCatWebhook
# 3) RevenueCat 대시보드 → Project → Integrations → Webhooks
#    URL  = https://us-central1-lettergo-147eb.cloudfunctions.net/revenueCatWebhook
#    Authorization header = (위 RC_WEBHOOK_AUTH 와 동일 값)
```
- 매핑: `*exact_drop_50/100/500` → brandExactDropCredits, `*brand_extra_1000` →
  brandExtraMonthlyQuota (premium/brand 구독은 RC entitlement 로 처리, grant 아님).
- `$RCAnonymousID*` app_user_id(로그인 전 anon)는 skip — Purchases.logIn(userId)
  이후 결제만 grant 대상.
- ⚠️ Blaze 플랜 + Admin SDK(Firestore write) 권한 필요(기본 admin.initializeApp 로 충족).

## deleteMyData — GDPR Art.17 서버 hard-delete (owner 검증, Phase 3 게이트)
탈퇴 시 client 가 못 지우는 본인 letters/문서를 Admin SDK 로 완전 삭제. 보안상
**users/{userId}.authUid == 호출자 ID토큰 uid** 인 본인만 허용 → 익명 auth(Phase 3
전)엔 authUid 부재로 거부(안전·단 삭제불가), **Phase 3 cutover 후 정상 동작**.
```bash
firebase deploy --only functions:deleteMyData
```
client(auth_service.deleteAccount)에서 ID토큰 + {userId} 로 POST 하도록 후속 배선
필요(Phase 3 활성 시점). 현재는 함수만 준비.

## generateCoupon — AI 쿠폰 생성 (현재 전 언어 Gemini Flash 단일)
매장(Brand)이 업종·설명만 입력 → LLM 이 카피/혜택 초안 생성. LLM 키는 서버 전용.
현재 라우팅: **전 언어 Google Gemini 2.0 Flash**(무료티어+최저가). 콘텐츠 모델 정합:
type=general/coupon/voucher, category=cafe/food/beauty/fashion/it/event/other.
```bash
# 1) Gemini 키 등록 (무료 발급: https://aistudio.google.com → Get API key)
firebase functions:secrets:set GEMINI_API_KEY
# 2) 배포
firebase deploy --only functions:generateCoupon
# 3) Cloud Run 공개: generatecoupon 서비스에 allUsers + Cloud Run 호출자
#    (org 정책 이미 완화됨 — 다른 함수와 동일)
# 4) 함수 URL 을 클라 빌드에 주입 (.env.local):
#    COUPON_AI_FN_URL=https://generatecoupon-sgtezc3c6q-uc.a.run.app
```
- 미설정(URL 없음) 시 compose 의 'AI 생성' 버튼은 자동 숨김.
- client: `CouponAIService.generate(...)` → 결과로 content/redemptionInfo 채움.
- **ko→Solar(국산) 도입(선택)**: index.js 상단 주석의 4단계 참고 (SOLAR_API_KEY
  defineSecret 복원 + secrets 배열 추가 + callSolar 복원 + ko 라우팅 분기).
