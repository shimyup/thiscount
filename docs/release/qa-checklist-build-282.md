# Build 282 — Device QA Checklist (정식 launch 직전)

TestFlight 282 (Delivery UUID `c37ae6e5-f93b-4d52-8526-b832d10d33c9`) 실기기 회귀
체크리스트. **App Store Submit 전 반드시 통과해야 하는 P0 4건** + 1 회귀 항목.

Build 282 = PR #8 (Build 274-281 통합) + PR #9 (282 bump) 머지 결과. 282 가
정식 launch 빌드 후보. 본 체크리스트는 5–10 분 안에 마무리 가능.

---

## 0) 사전 준비

- [ ] iPhone (iOS 14 이상) 또는 iPad 에 **TestFlight** 앱 설치
- [ ] 그 디바이스의 Apple ID 가 Internal Beta Group `Internal` 에 등록되어 있음
  (`shimyup@gmail.com` 이미 등록됨)
- [ ] TestFlight 앱 → Thiscount → 빌드 **282** 설치 / 업데이트
- [ ] 앱 첫 실행 → 온보딩 → 위치 권한 허용 (또는 거부)

---

## 1) P0 #1 — 만 14세 이상 동의 체크박스 (GDPR / KISA)

### Setup
신규 가입 흐름으로 진입 (이미 로그인되어 있으면 로그아웃 후 진행).

### 검증
- [ ] **회원가입 폼 6-1 (이용약관) 카드 바로 아래에 🎂 케이크 아이콘 카드 표시**
  - 한국어: "만 14세 이상입니다 (필수)"
  - 영어 (langCode=en): "I am 14 years or older (Required)"
  - 일본어/중국어/그 외 11개 언어 — 표시 언어와 일치
- [ ] **체크박스 미체크 상태**에서 가입 버튼이 **비활성화** (회색)
- [ ] 14세 동의만 체크하고 다른 동의는 안 한 상태에서 가입 버튼 **비활성**
- [ ] 개인정보 + 이용약관 + 14세 모두 체크하면 가입 버튼 **활성**
- [ ] 가입 완료 후 **iOS 시뮬 / 디바이스의 SharedPreferences** 에
      `consent_age_above14_ts` 가 timestamp 로 저장됨 (audit log)
  - 검증 방법: 다음 빌드의 로그에서 `prefs.getString('consent_age_above14_ts')`
    print 또는 디바이스 backup 분석

### Fail 시
- 카드 안 보임 → `lib/features/auth/screens/auth_screen.dart:1849` 의
  `_ConsentCard(checked: _agreeAgeAbove14, …)` 가 main 에 머지됐는지 확인.
- 가입 버튼이 14세 미체크에도 활성 → `_canSignUp` getter 가 `_agreeAgeAbove14`
  를 포함하는지 확인 (line 1124).

---

## 2) P0 #2 — ExactDrop 반경 100m enforcement (Brand 약속)

### Setup
Brand 계정으로 로그인 (또는 사용자가 Brand 권한 부여된 admin 계정 사용).
ExactDrop 크레딧이 있어야 함 (없으면 admin 권한으로 `adminGrantExactDropCredits(5)` 발동).

### 검증
- [ ] 발송 화면(`compose`) → 목적지 설정 → **ExactDrop 토글** 또는 보조
      옵션 탭
- [ ] ExactDropPicker 지도가 열리고 사용자 현재 위치를 중심으로 표시
- [ ] **현재 위치에서 약 1km 떨어진 좌표** 선택 → 확인 버튼
  → **즉시 빨간 snackbar "ExactDrop 은 현재 위치에서 100m 이내만 가능합니다."**
  표시됨, `_isExactDropped` 가 false 로 유지
- [ ] 현재 위치에서 50m 이내 좌표 선택 → 정상 통과, ExactDrop 마킹됨
- [ ] (advanced) 발송 직전 디바이스를 100m 이상 이동 → 발송 버튼 누름
  → **2차 검증** 으로 "ExactDrop out of range" snackbar 표시되며 발송 실패

### Fail 시
- 1km 좌표가 통과됨 → `lib/features/compose/screens/compose_screen.dart:1564`
  의 `distM > 100.0` 가드가 main 에 머지됐는지 확인.
- 메시지 다국어 안 됨 → `composeExactDropOutOfRange` 14언어 키 확인
  (`lib/core/localization/app_localizations.dart:9757`).

---

## 3) P0 #3 — EXIF GPS 메타데이터 제거 (Privacy)

### Setup
- iPhone 카메라 앱에서 **위치 정보 ON 상태로 사진 1장 촬영** (또는 GPS 메타가
  있는 기존 사진 사용)
- 그 사진의 EXIF 에 `GPSLatitude`, `GPSLongitude` 가 있음을 확인 (사진 앱
  Info 또는 [Pixspy](https://www.pixspy.com/) 같은 메타 추출 도구)

### 검증
A) **프로필 사진 변경** 흐름:
- [ ] 프로필 화면 → 프로필 이미지 탭 → "앨범에서 선택" → 위치 정보 있는 사진
- [ ] 변경 후 디바이스에서 사진 추출 (Finder iPhone backup 또는 AirDrop)
  - 추출 경로: 앱의 `getApplicationDocumentsDirectory()/profile_<ts>.jpg`
  - 추출 방법: **TestFlight 빌드는 직접 접근 어려움** — 대신 사진을 친구에게
    공유하는 방식으로 우회 검증 가능
- [ ] 추출된 사진의 EXIF 에 **GPS 필드 없음** (또는 EXIF 자체가 없음)

B) **편지 사진 첨부** 흐름 (기존 keepExif:false 확인):
- [ ] 발송 화면 → 사진 첨부 → 위치 정보 있는 사진 선택
- [ ] 발송 → 받는 사람 (또는 자신) 에게 도착한 사진 열기 → **저장 후 EXIF 확인**
- [ ] GPS 필드 없음

### Fail 시
- 프로필 사진에 GPS 잔존 → `lib/features/profile/profile_screen.dart:215`
  의 `FlutterImageCompress.compressAndGetFile(keepExif: false, …)` 가
  머지됐는지 확인.
- 편지 사진에 GPS 잔존 → `compose_screen.dart:889` 의 `_pickImage` 동일
  옵션 확인.

---

## 4) P0 #4 — `_launchSnsLink` XSS scheme 화이트리스트 (stored XSS)

### Setup
다른 사용자가 보낸 letter 에 SNS 링크가 있고 사용자가 그 letter 를 읽는 시나리오.
직접 테스트하려면 admin/dev 계정으로 letter 의 `socialLink` 필드를
악성 scheme 으로 설정.

### 검증
- [ ] Firestore 에서 letter 의 `socialLink` 필드를 `javascript:alert(1)` 로 수정
- [ ] 다른 디바이스/계정으로 그 letter 를 픽업 → 열기 → "SNS 링크 열기" 탭
- [ ] **빨간 snackbar "Invalid link scheme"** 표시되며 URL 실행 안 됨
- [ ] 정상 URL (`https://twitter.com/...`) 은 정상 동작

### Fail 시
- javascript: scheme 이 통과됨 → `lib/features/inbox/widgets/letter_read_screen.dart:147`
  의 `uri.scheme != 'http' && uri.scheme != 'https'` 가드 확인.

---

## 5) 회귀 — 기존 흐름 보장

### Beta 기능 OFF 확인 (정식 launch 빌드)
- [ ] 가입 후 **무료 Premium 자동 부여 X** (`BETA_FREE_PREMIUM=false`)
- [ ] 구독 화면 "업그레이드" 버튼 → **실제 Apple 결제 시트** 표시 (시뮬레이터
      아님)
- [ ] 관리자 패널 미노출 (`ceo@airony.xyz` 계정만 권한, 일반 계정에서 안 보임)

### 핵심 흐름
- [ ] 지도에서 가까운 핀 픽업 → 인박스 도착
- [ ] 인박스에서 letter 열기 → 코드/QR 정상 표시
- [ ] 구독 화면 진입 (`Profile → Premium`, `Settings → 구독`)
- [ ] OTP 인증 (Resend 발송)

### 14언어 회귀
- [ ] 한·영 외 1-2개 언어 (예: 일본어, 아랍어 RTL) 로 가입 흐름 진행 →
      14세 동의 카드 + ExactDrop 에러 메시지가 해당 언어로 표시

---

## 6) Pass 시 다음 단계

모든 항목 통과 시 정식 App Store Submit 진행 가능:
- 메타데이터 입력: `docs/release/app-store-connect-paste-ready.md`
- 스크린샷 6장 캡처: 6.7" `1290 x 2796` (사용자 직접)
- IAP 4종 가격 / 현지화 설정 (사용자 직접 ASC web UI)
- Submit for Review

## 7) Fail 시

- 어느 항목 fail 인지 메모 → 별도 sprint 로 fix → Build 283 빌드 + 재테스트
- main 워크트리에 직접 fix 가능한 항목 (코드 변경) → 즉시 commit + PR
- 인프라 변경 항목 (Cloud Functions, IAP 등) → 별도 sprint
