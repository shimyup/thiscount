# Letter Go — 보안 정책 (Build 207 기준)

이 문서는 Letter Go 앱의 보안·개인정보 모델, 운영 절차, 사고 대응을 정리한
것입니다. 코드/규칙 변경 시 이 문서도 함께 갱신해 주세요.

---

## 1. 데이터 분류

| 분류 | 예시 | 저장 위치 | 노출 정책 |
|------|------|-----------|-----------|
| **공개 가정 (PUBLIC-BY-DESIGN)** | 편지 본문, 첨부 사진, 쿠폰 코드 | Firestore `letters/{id}` | 누구나 read/list (지도 동기화 + 픽업) |
| **준공개 (SEMI-PUBLIC)** | username, country, isMapPublic=true 사용자 좌표(coarse) | Firestore `users/{id}` | rules: `isMapPublic==true` 일 때만 read |
| **민감 (SENSITIVE)** | 이메일, 전화번호, 비밀번호 hash, OTP | Flutter Secure Storage / Keychain | 디바이스 외부 노출 금지 |
| **운영 비밀 (SECRET)** | Twilio Auth Token, SendGrid/Resend API Key, RevenueCat Secret | `--dart-define` (빌드 시 주입) | 코드/리포지토리에 하드코딩 금지 |

⚠️ **클라이언트는 letter 본문이 공개 데이터인 것을 가정하고 사용해야 합니다.**
사용자에게 "이 편지는 누구나 읽을 수 있어요" 정책을 UI 에서 명확히 알려야 합니다.
민감 PII (전화번호, 주민번호 등) 가 본문에 입력되지 않도록 compose 화면에
가이드 문구가 필요합니다.

---

## 2. 인증 모델

```
┌─────────────────────┐
│ 사용자 식별 │
├─────────────────────┤
│ ① 이메일/SMS OTP │ ← 자체 인증 (AuthService)
│ ② Firebase Anonymous│ ← Firestore 접근용 토큰만
└─────────────────────┘
```

- **자체 OTP 인증** (`auth_service.dart`): 이메일 / SMS 6자리 코드, 10분
  유효, 윈도우당 5회 제한, 60초 쿨다운
- **Firebase Anonymous Auth**: 매번 바뀌는 1회용 UID. Firestore 접근 토큰
  발급용. owner-check 에 사용 불가능.
- **비밀번호 해시**: PBKDF2-SHA256 × 600,000 라운드 + 16바이트 랜덤 salt
  (Build 207 기준, OWASP 2023 권장값).

### 관리자 권한

- 관리자는 `BetaConstants.adminEmail` (dart-define `BETA_ADMIN_EMAIL` 주입)
  으로만 식별. 일치하는 이메일로 로그인하면 admin 메뉴·REST 권한 부여.
- **`BETA_DISABLE_IN_RELEASE=true` (default)** 면 릴리스 빌드에서 모든 베타
  override 가 자동 차단. 빌드 스크립트에 BETA_* 가 남아 있어도 사고 방지.

---

## 3. Firestore 규칙 요약 (`firestore.rules`)

| 컬렉션 | read | list | create | update | delete |
|--------|------|------|--------|--------|--------|
| users | isMapPublic 또는 owner | signedIn | signedIn | signedIn | signedIn |
| letters | 누구나 | 누구나 | signedIn + 검증 | signedIn + 화이트리스트 필드만 | ❌ |
| reports | ❌ | ❌ | signedIn | ❌ | ❌ |
| 기타 | ❌ | ❌ | ❌ | ❌ | ❌ |

### 핵심 검증 함수

- `isAnonLetterValid()` — `isAnonymous=true` 인 편지의 senderName 이 정확히
  `'__anonymous__'` sentinel 이고 senderId 가 `'anon_'` prefix 인지 확인.
  익명 letter 의 발신자 역추적을 서버 사이드에서 차단.
- `isValidLetterCreate()` — 본문 5,000자 이하, 필수 필드 타입 검증.
- `isAllowedLetterUpdate()` — pickup/redeemed/read/like/rating 카운터 + 도착
  상태(arrivedAt, readAt, status) 만 변경 허용. **본문·발신자·좌표·카테고리
  는 immutable**.

---

## 4. Storage 규칙 요약 (`storage.rules`)

> ⚠️ **현재 Storage 비활성** — Firebase 가 2024 부터 Storage 를 Blaze
> (종량제) 플랜 전용으로 변경. 프로젝트가 Spark (무료) 플랜이라면
> `FIREBASE_STORAGE_ENABLED=false` 로 두고 클라이언트에서 업로드 자체를
> skip 한다 (`storage_service.dart` 가 즉시 null 반환 → 호출자가 로컬 경로
> 사용). 사용자 이미지는 디바이스에만 저장되며 다른 기기에서 안 보인다.
>
> Blaze 업그레이드 후:
>   1. Firebase Console > Storage > 시작하기 → 위치 `asia-northeast3` 선택
>   2. `firebase deploy --only storage` 로 아래 규칙 적용
>   3. 빌드 시 `--dart-define=FIREBASE_STORAGE_ENABLED=true` 주입


| 경로 | read | write | delete |
|------|------|-------|--------|
| `vouchers/**` | signedIn | signedIn + image/* + 10MB | signedIn |
| `letters/**` | signedIn | signedIn + image/* + 10MB | signedIn |
| `profile/{uid}/**` | signedIn | signedIn + image/* + 10MB | signedIn |
| `brand_ads/**` | signedIn | ❌ (admin REST) | ❌ |
| 기타 | ❌ | ❌ | ❌ |

---

## 5. 클라이언트 보안 강화 포인트 (Build 207)

### 익명 편지
`AppState._saveLetterToFirestore` 가 `letter.isAnonymous=true` 일 때
- `senderId` → `'anon_${letter.id}'` (역추적 불가)
- `senderName` → `'__anonymous__'` sentinel
- `originLat/Lng` → `destinationLocation` 좌표로 동일화 (출발지 노출 차단)

### GPS 정밀도
`_saveUserToFirestore` 는 위도·경도를 **소수점 3자리(~110m)** 로 round 후
업로드. 픽업 반경(200m–1km) 게임플레이 영향 없이 자택 핀포인트 차단.

### 로컬 암호화
`_decryptStr` 는 손상/외부 주입 데이터에 대해 **빈 문자열 반환**. 이전엔
평문 fallback 으로 인해 위변조 데이터가 그대로 통과할 위험이 있었음.

### OTP 노출
릴리스 빌드(`kReleaseMode==true`) 에서는 OTP 코드를 **클라이언트로 절대
반환하지 않음**. SMS/이메일 발송 실패 시에도 코드는 서버 채널로만.

### 백그라운드 위치
iOS Info.plist 의 `NSLocationAlwaysAndWhenInUseUsageDescription` 제거.
`When In Use` 만 요청 → 백그라운드 추적 권한 자체를 받지 않음.

### 회원 탈퇴
`AuthService.deleteAccount` 가:
1. `users/{id}` 문서 삭제
2. 본인이 보낸 letters 의 status 를 `'deletedBySender'` 로 mark (rules 가
   삭제 자체는 막아 hard-delete 는 admin REST 후속 처리)
3. SharedPreferences clear + Secure Storage wipe

---

## 6. 운영 절차 — 배포 체크리스트

[deploy-checklist.md](./docs/security/deploy-checklist.md) 참고.

매 릴리스 전 반드시:
1. `flutter analyze` clean
2. `flutter test` 모두 pass
3. `firebase deploy --only firestore:rules,storage` (rule 파일 변경 시)
4. `BETA_FREE_PREMIUM` / `BETA_ADMIN_EMAIL` 환경변수가 빌드 스크립트에서
   제거됐는지 확인 (또는 `BETA_DISABLE_IN_RELEASE=true` 가 default 인지 확인)
5. GCP Console > Credentials 에서 Firebase API Key 의 iOS bundleID /
   Android packageName / web origin 제한 확인

---

## 7. 사고 대응

### 데이터 유출 의심 시
1. 즉시 firestore.rules 의 letters/users `read` 를 `if false` 로 변경 후 deploy
2. 영향 받은 사용자 식별 (Firestore audit log)
3. 새 Firebase API Key 발급 + 기존 키 revoke
4. 사용자 공지 (in-app + email)

### API 키 노출 시
1. GCP Console 에서 즉시 key revoke
2. 신규 key 발급 + restriction (bundle ID / referrer) 설정
3. dart-define 주입 빌드로 재배포
4. 이전 빌드 사용자에게 강제 업데이트 푸시

### 관리자 계정 탈취 의심 시
1. `BETA_ADMIN_EMAIL` 빈 값으로 빌드 + 즉시 배포
2. admin REST 엔드포인트 호출 로그 확인
3. 영향 letters/users 백업 복원

---

## 8. 개선 로드맵 (TODO)

- [ ] **Custom Auth Token**: 자체 OTP 인증 → Firebase Custom Token 발급으로
      이전. anonymous UID 가 아닌 영구 UID 로 owner-check 활성화.
- [ ] **Brand 인증 Cloud Function**: `submitBrandVerification` 의 자가 승인
      을 서버 사이드 워크플로로 이전. 현재 클라이언트 자가 승인은 베타 한정.
- [ ] **End-to-End 암호화**: DM 도입 시 letter 본문 클라이언트-사이드 암호화
      검토.
- [ ] **데이터 보존 정책**: letter 자동 만료(30일/90일) cron job, 사용자
      활동 없을 때 1년 후 자동 익명화.
- [ ] **API Key Restriction 자동화**: GCP Cloud Build 배포 시 key restriction
      자동 적용 (현재 수동).
- [ ] **PII Linter**: compose 본문에 전화번호·주민번호 정규식 매칭되면 경고.

---

문의: ceo@airony.xyz
