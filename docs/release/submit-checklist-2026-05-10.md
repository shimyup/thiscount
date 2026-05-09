# Thiscount App Store Submit Checklist (Build 273)

Last updated: 2026-05-10

정식 App Store Submit 직전 단계별 체크리스트. 각 항목 완료 후 □ → ✅.

---

## Phase 1 — 코드 (모두 완료 ✅)

```
✅ Build 273 코드
  ✅ 5개 화면 1순위 액션 가시성 (홈/탐색/등록/결제/마이) — 8 fix
  ✅ 50회 시뮬레이션 P0/P1 — 12 fix (trial, brand, filter, location, etc.)
  ✅ Audit 28건 (보안/글로벌/크래시/문서) — 13 fix + 15 verified
  ✅ 14개 언어 풀 번역 (Build 271-272 신규 위젯 13 keys × 14 langs)
  ✅ permanentAdminEmail dart-define 화 (보안 강화)
  ✅ trialExpiry null safety
  ✅ LaunchImage 1024 교체 (빌드 경고 해소)
  ✅ NSCameraUsageDescription 제거 (실제 미사용)
  ✅ pubspec flutter: ">=3.27.0" 명시 (withValues alpha 호환)
  ✅ flutter analyze: No issues found
```

---

## Phase 2 — 빌드·배포 (모두 완료 ✅)

```
✅ Build 273
  ✅ Archive 생성 (266MB)
  ✅ Manual signing IPA Export (41MB)
  ✅ TestFlight 업로드 (Delivery UUID: 1007c3a5-4efa-420f-8e04-6989ecb447f0)
  ✅ Apple validation: BUILD-STATUS VALID
  □ TestFlight Processing 완료 → Ready to Test (~10분 후)
```

---

## Phase 3 — 외부 인프라 (사용자 manual)

### 3.1 thiscount.io 도메인 + 정적 호스팅

```
□ 도메인 활성 (Namecheap May 2026~)
□ DNS 설정 (GitHub Pages / Cloudflare Pages / Vercel 중 택1)
□ 페이지 라이브 검증
  □ https://thiscount.io/privacy.html → 200 OK + 한·영 toggle 동작
  □ https://thiscount.io/terms.html → 200 OK
  □ https://thiscount.io/support.html → 200 OK
  □ https://thiscount.io/ → 마케팅 랜딩 또는 redirect
□ HTTPS 인증서 유효
```

가이드: [docs/release/hosting-thiscount-io.md](hosting-thiscount-io.md)

### 3.2 App Store Connect 메타데이터

```
□ App 정보
  □ Name: Thiscount
  □ Subtitle (ko): 근처 혜택을 줍는 쿠폰 지갑
  □ Subtitle (en): Pick up rewards near you
  □ Primary Category: Lifestyle
  □ Secondary Category: Shopping
  □ Content Rights: No

□ Pricing & Availability
  □ Price: Free
  □ Territories: All (또는 한국 + 호주 우선)

□ App Privacy URLs
  □ Privacy Policy URL: https://thiscount.io/privacy.html
  □ Support URL: https://thiscount.io/support.html
  □ Marketing URL: https://thiscount.io

□ Listing Text
  □ Korean (ko): Promotional Text + Keywords + Description + What's New
  □ English (en): 동일 4개 항목
  □ (선택) 다른 12개 언어 ja/zh/fr/de/es/pt/ru/tr/ar/it/hi/th — launch 후 추가도 OK

□ App Review Information
  □ Contact First/Last Name: Airony / Team
  □ Phone Number: 실사용 번호로 교체 (+82-10-...)
  □ Email: ceo@airony.xyz (또는 support@thiscount.io)
  □ Sign-in: No (reviewer 가 in-app 가입 가능)
  □ Notes for Review: paste-ready 의 7번 항목

□ App Privacy Details (App Store Connect 의 별도 입력 폼)
  □ Data Collection: Name, Email, UserID, PreciseLocation, PhotosVideos,
    OtherUserContent, PurchaseHistory, DeviceID
  □ Data Use: App Functionality only
  □ Linked to User: Yes
  □ Used for Tracking: No
```

paste-ready: [docs/release/app-store-connect-paste-ready.md](app-store-connect-paste-ready.md)

### 3.3 In-App Purchases (App Store Connect 설정)

```
□ Subscription Group: "Thiscount Premium"
  □ thiscount_premium_monthly_ios — Premium Monthly (1 month, ₩4,900)
  □ thiscount_brand_monthly_ios — Brand Monthly (1 month, ₩99,000)

□ Non-renewing
  □ thiscount_gift_1month_ios — Gift Card 1 Month (₩3,900)
  □ thiscount_brand_extra_1000_ios — Brand Extra 1000 sends (₩9,900)

□ 각 product 의 Localized 정보 (ko + en minimum)
  □ Display Name
  □ Description
  □ Promotional Image (선택)

□ Subscription Terms
  □ Trial: 3-day free trial 명시 (또는 in-app local entitlement 으로 처리 — Apple 검증 필요)
  □ Auto-renewal: Yes / No 정책 명시
```

### 3.4 스크린샷 (사용자 manual)

```
□ 6.7" iPhone (1290×2796) — 6장 필수
  □ 01-map (지도 + 주변 핀)
  □ 02-inbox (인박스 + 필터 칩)
  □ 03-coupon-detail (쿠폰 상세)
  □ 04-premium (Premium 구독 + trial 배너)
  □ 05-compose-brand (Brand 캠페인 발송)
  □ 06-profile (프로필)

□ 6.5" iPhone (1284×2778) — App Store Connect 자동 변환 가능
□ iPad Pro 12.9" — iPad 지원 시 필수
□ 캡션 (ko + en)
```

가이드: [docs/release/screenshot-capture-guide-2026-05-10.md](screenshot-capture-guide-2026-05-10.md)

---

## Phase 4 — 정식 launch 빌드 (Build 274 또는 이후)

베타 flag 정리 후 production 빌드:

```
□ .env.local 정리
  □ BETA_FREE_PREMIUM 제거 (또는 false)
  □ BETA_UPGRADE_SIMULATOR=false (명시)
  □ BETA_ADMIN_EMAIL 제거 (또는 빈 값)
  □ BETA_DISABLE_IN_RELEASE=true 유지
  □ PERMANENT_ADMIN_EMAIL: 운영 admin 이메일 또는 제거

□ pubspec version bump
  □ Build 274 또는 +1 (TestFlight 처리 완료된 271-273 위)

□ Archive + Export + Upload
  □ IOS_BUILD_MODE=ipa ./scripts/build_ios_release.sh
  □ Manual signing export (이전과 동일 흐름)
  □ altool --upload-app

□ App Store Connect
  □ Build 선택 (TestFlight 에서 Production 으로)
  □ Export Compliance: HTTPS only → "No" (추가 암호화 없음)
  □ Submit for Review
```

`.env` 정리 가이드: [.env.example](../.env.example) (Build 273 업데이트)

---

## Phase 5 — Submit for Review

```
□ App Store Connect → Apps → Thiscount → "Add for Review"
□ 모든 메타데이터 / 스크린샷 / IAP / Build 선택 완료
□ Compliance / Encryption: ITSEncryptionExportComplianceCode = "No"
□ Submit
□ Apple 응답 대기 (보통 24-48h)
```

---

## Phase 6 — Launch Day

```
□ Apple 승인 후 "Manually release" 또는 "Automatic" 선택
□ 출시 후 24h 내 모니터링
  □ Crashes: Firebase Crashlytics 또는 App Store Connect Crash Reports
  □ Reviews: 1-star 리뷰 즉시 응답
  □ Server: Firestore reads/writes 폭증 대비
  □ TestFlight 베타 사용자에게 launch 알림
  □ Marketing: SNS / 보도자료 / 매장 입점 사업자 안내
```

---

## 🚨 중요 위험 항목

1. **Subscription Trial 처리**: 현재는 in-app local entitlement (3일 free Premium). App Store Review 가 "왜 StoreKit introductory offer 안 쓰냐?" 물을 수 있음. 답변 준비:
   - "Local 3-day trial 은 사용자가 Apple ID 결제정보 없이 onboarding 가능하게 함. 이후 결제 화면에서 명시적으로 구매 버튼 누를 때만 StoreKit 호출."
   - 향후 StoreKit Introductory Offer 로 마이그레이션 검토.

2. **위치 데이터**: NSPrivacyCollectedDataTypePreciseLocation 명시했지만 "Track Across Apps" 는 NO. 다른 SDK (Firebase) 가 위치 수집 안 하는지 재확인.

3. **UGC**: 사용자 작성 메시지가 부적절 콘텐츠 포함 가능. 신고/차단 기능 letter_read_screen.dart 에 구현됨 — 24h 응답 SLA 약속 (Apple 4.4 충족).

4. **Brand 광고 모달**: BrandAdModal 이 광고로 분류되면 ATT 필요. 현재는 "앱 내 콘텐츠 (코인/쿠폰)" 로 분류 — App Store Review 와 협의 가능.

5. **외부 결제 안내 없음**: RevenueCat / StoreKit 만 사용. 외부 link 통한 결제 유도 없음 (Apple 5.1.1 충족).

---

## 다음 단계

이 시점에서 **사용자가 App Store Connect 대시보드에 접속해서 manual 작업**:

1. https://appstoreconnect.apple.com → Apps → Thiscount
2. **TestFlight** 탭에서 Build 273 처리 완료 확인 (Ready to Test)
3. **App Store** 탭에서 paste-ready.md 의 내용 입력
4. **In-App Purchases** 등록 (4개 product)
5. **Screenshots** 업로드 (사용자 캡처)
6. **Submit for Review** 클릭

이 모든 작업이 끝나면 Apple 응답 대기 (24-48h).
