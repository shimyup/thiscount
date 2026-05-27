# Account Type Split — General vs Brand (NN 시리즈)

Build 405 부터 적용되는 회원 종류 분리 아키텍처.

## 가입 흐름

```
[ 가입 진입 ]
       │
       ▼
[ NN1: 계정 종류 선택 화면 ]
   ┌───────────┬───────────┐
   │ 일반 회원 │ 브랜드     │
   └───────────┴───────────┘
       │           │
       ▼           ▼
[ NN2: 가입 form — 동일 ]   (Brand 시 isBrand=true, brandName 추가 저장)
       │
       ▼
[ OTP 인증 ]
       │
       ▼
[ MainScaffold (NN3 분기) ]
```

## MainScaffold 탭 구성

| 탭 # | 일반 회원 | Brand 계정 | 데이터 source |
| --- | --- | --- | --- |
| 0 | 🗺 지도 | 🗺 지도 (공유) | `state.worldLetters`, `state.currentUser.lat/lng` |
| 1 | 📦 인박스 | 📣 캠페인 | `state.inbox` vs `state.sent` |
| 2 | 👤 프로필 | 👤 프로필 (공유) | `state.currentUser` |
| 중앙 | 💎 업그레이드/✉️ 보내기 | 📣 캠페인 발송 | compose 진입 |

## 공유 시스템 (두 계정이 함께 쓰는 데이터/서비스)

코드베이스에서 **둘 다** 사용하는 시스템 — 변경 시 두 흐름 모두 검증 필수.

### 1. 지도 데이터
- `state.worldLetters` — 전 세계 쿠폰 위치 (일반은 줍기 대상, Brand 는 본인 캠페인 위치 추적)
- `state.brandZones` — Brand auto-drop zone (공통 캐시; 일반 회원도 zone 안에 들어가면 letter 받음)

### 2. 회원 위치
- `state.currentUser.latitude / longitude` — GPS 현재 위치
- `state.lastKnownLat / Lng` — 마지막 GPS 캐시 (둘 다 공유)
- Firestore `users/{uid}/lat,lng` — 다른 사용자 지도 마커

### 3. 인증·계정 시스템
- `AuthService` — login / signUp / OTP / password
- `UserProfile` — 두 종류 동일 모델 (`isBrand` 필드로만 분기)
- Secure storage 키 `_keyIsBrand` 가 type 결정

### 4. 결제·구독
- `PurchaseService` — RevenueCat (두 종류 공유; Brand 는 99,000원 별도 구독)
- Welcome trial — 일반 회원만 3일 Premium 부여

## 분리된 시스템 (한 계정만 쓰는 데이터/UI)

### 일반 회원 전용
- `state.inbox` — 받은 쿠폰 list
- `state.unreadCount` — 읽지 않은 letter badge
- `InboxScreen` — 필터/정렬/만료 사이렌 UI
- `_DailyGreetingPill`, `_NearbyAlertBanner` — 픽업 안내 floating UI
- 답장 흐름 (`hasReplied`, reply CTA)

### Brand 전용
- `state.sent` — 발송 캠페인 list (Brand 의 인박스 대체)
- `BrandCampaignScreen` — 캠페인 dashboard
- `BrandInsightsScreen` — 분석 화면
- `state.brandMostRecentlyPickedUpLetter` — 최근 픽업 highlight
- `BrandPromoBanner` (일반 사용자 지도에 노출됨 — Brand 본인은 hide)
- Compose 화면의 `_buildBrandOptions` 섹션 (대량/auto-zone/exact drop)
- ExactDrop 패키지 결제 (100/500 letter)

## 향후 작업 (NN 시리즈 후속)

- **NN6 후보**: Brand 인증 절차 (사업자등록증 업로드 → admin 승인). 현재는 self-attestation 으로 즉시 isBrand=true.
- **NN7 후보**: 계정 종류 전환 (settings 에서 일반 → Brand 또는 반대). 현재는 가입 시점에 fixed.
- **NN8 후보**: Brand 계정의 Welcome trial 정책 — 현재는 trial 없음 (Brand 는 Premium 가치 일부 중복). 별도 onboarding offer 필요.

## 일관성 invariant

- 한 사용자는 한 종류만 (`isBrand` 가 true 또는 false 둘 중 하나).
- 두 종류 모두 동일 Firestore `users/{uid}` 경로 사용 — `isBrand` 필드로 구분.
- 지도 마커는 두 종류 모두 동일 source (`state.mapUsers`); UI 만 다르게 표시.
- 위치 기반 픽업 cooldown 은 두 종류 동일 (Brand 도 줍기 가능 — Build 216 부터).
