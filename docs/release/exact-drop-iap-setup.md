# ExactDrop 100통 패키지 IAP 등록 가이드 (Build 324)

> Brand 사장 시뮬레이션 발견 — "토요일 오후 100통 소진 시 ceo@airony.xyz 메일
> → 답 기다림" UX 였음. Build 324 에서 즉시 IAP 구매 흐름 추가 (`buyExactDrop100`
> + paywall 다이얼로그의 "100통 구매" 버튼). 이 코드는 **콘솔 등록 전까지는
> 동작 안 함** — 등록 후 RC 매핑 + sandbox 검증까지 완료해야 정식 작동.

> 기존 4 상품 (Premium 월간 / Brand 월간 / Gift 1개월 / Brand Extra 1000)
> 설정 흐름은 [`iap-setup-guide.md`](./iap-setup-guide.md) 참고. 이 문서는
> ExactDrop 1개 상품에 한정한 추가 작업만 다룬다.

---

## 사전 확인

- [ ] Apple Developer Program **유효** (Airony company inc.)
- [ ] **Paid Applications Agreement** 활성 (계약·세금·은행 모두 검증 완료)
- [ ] RevenueCat 프로젝트 (Thiscount) 에 기존 4 상품 등록 정상 작동 중
- [ ] Google Play Console 에 앱 배포 권한 (관리자 또는 Finance 권한)

---

## 1. App Store Connect (iOS)

### 1.1 IAP Product 신규 등록

ASC → 앱 (Thiscount) → 우측 사이드바 **인앱 구매** 탭 → "관리" → 좌측 **"+"** → **소모성** 선택

| 필드 | 값 |
|---|---|
| 참조 이름 | `ExactDrop 100 Package` |
| 제품 ID | **`thiscount_exact_drop_100_ios`** ⚠️ 코드와 정확히 일치 |
| 가격 | **₩10,000** (한국 — Tier 10) |
| 가용성 | 모든 영역 (또는 KR/JP/US 등 출시 국가만) |

⚠️ 제품 ID 는 한 번 등록하면 변경 불가. **`thiscount_exact_drop_100_ios`** 정확히 입력.

### 1.2 현지화 (14 언어)

App Store Connect 는 모든 출시 언어에 현지화 필요. 최소 한국어 + 영어는 필수.

#### 한국어 (ko)
- 표시 이름: `ExactDrop 크레딧 100통`
- 설명: `원하는 매장·좌표에 정확히 100통의 혜택을 뿌릴 수 있어요. 1회 구매 시 100통 자동 충전.`

#### 영어 (en)
- Display name: `ExactDrop 100 Credits`
- Description: `Drop 100 promos on exact store locations or coordinates. One-time purchase adds 100 credits instantly.`

#### 일본어 (ja)
- 表示名: `ExactDrop 100クレジット`
- 説明: `店舗や正確な座標に100通の特典を配信。購入で100クレジット即時追加。`

#### 중국어 (zh)
- 显示名称: `ExactDrop 100次额度`
- 描述: `精确投放100次优惠到指定地点。购买后立即获得100额度。`

#### 기타 (fr/de/es/pt/ru/tr/ar/it/hi/th)
출시 시점에 i18n 팀에 위 패턴으로 번역 의뢰. 출시 안 한 언어는 영어로 fallback OK.

### 1.3 심사용 자료

ASC 가 IAP 제출 시 요구하는 두 가지:

**스크린샷 (필수)**
- 해상도: 1284 × 2778 (iPhone 14 Pro Max 기준) 또는 1242 × 2208 (legacy)
- 캡처: TestFlight 빌드에서 compose 화면 → "🎯 정확 좌표 단건" 시나리오 칩 → ExactDrop paywall 다이얼로그 → "100통 구매 (₩10,000)" 버튼이 보이는 시점
- 위치: `docs/release/iap_screenshot_guides/exact_drop_100.png` 에 저장 (기존 가이드 패턴 따름)

**검토용 메모 (필수)**
```
ExactDrop is a Brand-only feature that allows verified business owners
to drop promos on exact map coordinates (precise pin) rather than random
city distribution. The 100-credit package is a one-time consumable purchase
that adds 100 ExactDrop credits to the Brand account's balance, consumed
1-by-1 per send. No subscription, no recurring charges.

Access:
1. Sign up with a Brand-tier account (Brand verification required)
2. Navigate to the compose screen
3. Tap "🎯 Exact location" scenario chip OR enable the ExactDrop toggle
4. If balance is 0, the paywall dialog appears with the "Buy 100 promos
   (₩10,000)" button — purchase triggers Apple StoreKit payment sheet.
5. After successful purchase, the 100 credits are added immediately and
   the ExactDrop pin selector opens automatically.

Test account credentials (provided to Apple reviewer separately).
```

### 1.4 제출 준비 완료 상태 확인

ASC IAP 페이지에서 상품 상태가 **"제출 준비 완료"** 표시되는지 확인. "메타데이터 누락" 이면 빨간 박스에 누락 필드 표시 — 채워야 함.

⚠️ 제출 준비 완료 ≠ 승인. 다음 앱 빌드 제출 시 IAP 도 함께 심사 → 승인 후 sandbox 테스트 가능.

---

## 2. Google Play Console (Android)

### 2.1 IAP Product 신규 등록

Play Console → 앱 (Thiscount) → 좌측 메뉴 **수익화** → **앱 내 상품** → 우측 **"상품 만들기"**

| 필드 | 값 |
|---|---|
| 제품 ID | **`letter_go_exact_drop_100`** ⚠️ 코드와 정확히 일치 |
| 이름 | `ExactDrop 크레딧 100통` (한국어) |
| 설명 | `원하는 매장·좌표에 정확히 100통의 혜택을 뿌릴 수 있어요.` |
| 기본 가격 | **₩10,000** |
| 상태 | **활성** |

⚠️ Play Console 의 product ID 는 한 번 등록하면 변경 불가. 또한 iOS 와 다른 ID 인 이유:
Android 는 Legacy ID (`letter_go_*` prefix) 가 RevenueCat import 시 자동 매핑된 흔적.
새 상품도 같은 prefix 유지가 RC offering 자동 인식에 안전.

### 2.2 가격 추가 시장 설정

기본 가격 ₩10,000 입력 후 "환율 자동 적용" 선택 → 모든 출시 국가에 자동 변환된 가격 노출.
주요 시장 수동 조정 권장:
- 미국 (USD): $7.99
- 일본 (JPY): ¥1,200
- 유럽 (EUR): €7.99

### 2.3 라이선스 테스터 추가

Play Console → 설정 → **라이선스 테스트** → 테스터 Gmail 추가.
이 계정은 sandbox 결제 시 실제 청구 X.

---

## 3. RevenueCat Dashboard

https://app.revenuecat.com → 프로젝트 (Thiscount) → 좌측 메뉴

### 3.1 Products 등록

**Products** 탭 → **"+ New"** 2개 등록:

| Display name | Store product ID | Store |
|---|---|---|
| ExactDrop 100 (iOS) | `thiscount_exact_drop_100_ios` | App Store |
| ExactDrop 100 (Android) | `letter_go_exact_drop_100` | Play Store |

⚠️ Type 은 둘 다 **Non-Subscription** (one-time consumable).

### 3.2 Entitlement — 매핑 불필요

ExactDrop 은 entitlement 가 없는 순수 consumable. RC 의 Entitlements 탭은 건드릴 필요 없음.
`buyExactDrop100()` 코드가 구매 성공 후 `adminGrantExactDropCredits(100)` 직접 호출 →
entitlement 검증 우회.

### 3.3 Offerings 추가

**Offerings** 탭 → `default` offering → **"Add package"** 2개:

| Package ID | Product (iOS) | Product (Android) |
|---|---|---|
| `exact_drop_100` | `thiscount_exact_drop_100_ios` | `letter_go_exact_drop_100` |

⚠️ Package ID 는 자유 — `exact_drop_100` 권장 (코드의 `PurchaseProductIds.exactDrop100Candidates()` 가 두 store ID 직접 검색하므로 RC package ID 와 무관).

### 3.4 Webhook (선택)

이 상품은 entitlement 없는 consumable 이라 RC webhook 불필요. RC 가 자동으로 transaction 영구 기록은 하지만 (replay 차단), 클라이언트 측 grant 가 즉시 호출되므로 server-side 검증 흐름 없음.

추후 fraud 방지 강화 시 RC webhook → Cloud Function → Firestore `exactDropPurchases/{transactionId}` 기록 패턴 검토.

---

## 4. Sandbox 테스트 (출시 전 필수)

### 4.1 iOS Sandbox

1. ASC → 사용자 및 액세스 → **샌드박스 사용자** → "+" → 새 Apple ID 생성 (가짜 이메일 OK, 예: `qa-exact-drop-2026@test.com`)
2. iPhone 설정 → **App Store** → 하단 **샌드박스 계정** 섹션 → 위 sandbox Apple ID 로 로그인
3. TestFlight 빌드 (Build 324+) 설치 → Brand 계정으로 로그인
4. compose 화면 → 🎯 "정확 좌표 단건" 칩 탭 → paywall 다이얼로그 노출 확인
5. **"100통 구매 (₩10,000)"** 버튼 탭 → Apple 결제 sheet 떠야 함
6. 결제 sheet 상단에 **"이것은 샌드박스 결제입니다"** 빨간 배너 확인
7. Touch ID / Face ID 또는 비밀번호 입력 → 결제 완료
8. 자동으로 ExactDrop 진입 (코드의 `unawaited(_selectExactDrop())`) — `state.brandExactDropCredits` 가 100 으로 표시되는지 확인

### 4.2 Android Sandbox (라이선스 테스터)

1. Play Console → 설정 → **라이선스 테스트** → 테스터 Gmail 확인
2. 그 Gmail 로 로그인된 Android 기기에 TestFlight 빌드 설치
3. Brand 계정 로그인 → compose → 🎯 정확 좌표 단건 → "100통 구매" 버튼
4. Google Play 결제 sheet 상단 **"테스트 카드, 청구되지 않음"** 배너 확인
5. 결제 완료 → ExactDrop 진입 → balance 100 확인

### 4.3 검증 체크리스트

- [ ] paywall 다이얼로그의 "100통 구매" 버튼이 보임 (gold 색 + 쇼핑카트 아이콘)
- [ ] 탭 시 Apple/Google 결제 sheet 떠짐
- [ ] sandbox 표시 확인 (실 결제 아님)
- [ ] 결제 완료 후 SnackBar 노출: `🎯 ExactDrop +100 (100)`
- [ ] 자동으로 ExactDrop 핀 선택 화면 진입
- [ ] `state.brandExactDropCredits` getter 가 100 반환
- [ ] 다음 ExactDrop 발송 시 1 차감 (99 → ...)
- [ ] 0 까지 사용 후 다시 paywall 떠짐 (재구매 가능)
- [ ] 동일 sandbox 계정 재구매 시 정상 동작 (consumable 이라 replay OK)
- [ ] 앱 종료 → 재실행 후에도 credit 잔량 유지 (Firestore + SharedPreferences 양쪽 sync)
- [ ] 다른 디바이스 로그인 시 server 의 brandExactDropCredits 가 복원됨

---

## 5. 출시 흐름

### 5.1 ASC 빌드 제출
1. Build 324+ 빌드를 TestFlight 에 업로드 (`./scripts/release_to_testflight.sh`)
2. ASC → 빌드 → 새 버전 (예: 1.0.0) → **"인앱 구매"** 섹션에서 신규 ExactDrop 100 상품 체크 (기존 4개 + 신규 1개 = 5개 체크)
3. "심사용 메모" 에 ExactDrop 추가 설명 (위 1.3 의 영어 메모 복붙)
4. 심사 제출 → Apple 승인 (보통 24-48h)

### 5.2 Play Console 빌드 제출
1. AAB 업로드 (`./scripts/build_android_release.sh`)
2. Play Console → 출시 → 프로덕션 → 새 출시 → 빌드 선택
3. **"앱 내 상품"** 섹션이 자동으로 모든 active 상품 포함
4. 심사 제출 → Google 승인 (보통 12-24h)

### 5.3 출시 후 모니터링
- RevenueCat Dashboard → Charts → "Revenue" / "Active Subscriptions" 에 ExactDrop transaction 노출 확인
- Firestore `users/{uid}` 의 `brandExactDropCredits` field 값 sample 검증
- App Store / Play Console 의 매출 보고서에서 `thiscount_exact_drop_100_ios` / `letter_go_exact_drop_100` transaction count 확인

---

## 6. 트러블슈팅

| 증상 | 원인 | 해결 |
|---|---|---|
| paywall 다이얼로그가 안 뜸 | Brand 계정 아님 / `state.canUseExactDrop` true (credit 있음) | Brand 인증 + credit 0 상태 확인 |
| "100통 구매" 버튼 탭 시 결제 sheet 안 뜸 | RC offering 미매핑 | 3.1 / 3.3 다시 확인 |
| 결제 완료 후 credit 안 늘어남 | `adminGrantExactDropCredits` 미호출 — _isTestMode 경로 분기 확인 | `_isRcKeyConfiguredForCurrentPlatform` true 인지 + `purchase_service.dart:1037` `buyExactDrop100` debugPrint 추가해 흐름 추적 |
| sandbox 결제 sheet 가 실 결제 sheet 처럼 보임 | 일반 Apple ID 로 로그인됨 | 설정 → App Store → 일반 계정 로그아웃 후 sandbox 계정 로그인 |
| Android 에서 "상품 ID 못 찾음" | Play Console 상품 비활성 / 빌드 버전 mismatch | Play Console 상품 상태 "활성" 확인 + 빌드 versionCode 가 등록된 트랙 (internal/closed/production) 에 업로드됐는지 |
| RC 가 "Offering not found" 디버그 로그 | offering 명 mismatch | RC dashboard `default` offering 이 "Current" 상태 확인 |
| "Apple 결제 인증 실패" Android | platform mismatch — iOS Sandbox Apple ID 로 Android 결제 시도 | 각 플랫폼별로 다른 테스트 계정 사용 |

---

## 7. 보안 고려 사항

- **Replay 차단**: Apple/Google + RevenueCat 가 transaction ID 별 1회 처리 보장. 동일 transaction 으로 재시도해도 RC 가 차단.
- **Server-side 검증 누락**: 현재 `buyExactDrop100` 은 client-side grant (`adminGrantExactDropCredits`). 악의적 사용자가 클라이언트 modification 으로 무한 grant 가능. 출시 후 fraud signal 감지 시 RC webhook → Cloud Function 으로 transaction id 별 entitlement 검증 추가 권장.
- **Refund 처리**: Apple/Google 환불 시 RC 가 webhook 으로 알림. 현재 코드는 환불 시 credit 차감 안 함. 추후 server-side hook 으로 `adminGrantExactDropCredits(-100)` 또는 직접 차감 처리 검토.

---

## 8. 코드 참조 (변경 불필요 — 정보용)

| 파일 | 위치 | 역할 |
|---|---|---|
| `lib/core/services/purchase_service.dart` | `PurchaseProductIds.exactDrop100` | iOS/Android product ID 분기 |
| 동 파일 | `PurchaseProductIds.exactDrop100Candidates()` | RC offering 검색 시 다중 후보 |
| 동 파일 | `PurchaseService.buyExactDrop100(AppState)` | 구매 트리거 + grant 호출 |
| 동 파일 | `PurchaseOperation.exactDrop100` | UI 로딩 상태 enum |
| `lib/state/app_state.dart` | `adminGrantExactDropCredits(int)` | 100 credit 즉시 grant + Firestore sync |
| 동 파일 | `consumeExactDropCredit()` | 발송 시 1 차감 |
| 동 파일 | `brandExactDropCredits` getter | 현재 잔량 |
| `lib/features/compose/screens/compose_screen.dart` | `_selectExactDrop()` paywall 다이얼로그 | "100통 구매" 버튼 → buyExactDrop100 호출 |
| `lib/core/localization/app_localizations.dart` | `composeExactDropPaywallBody/OutOfCredits/BuyBtn` | 14언어 카피 |

---

## 9. 자주 묻는 질문

**Q: ExactDrop 가격 ₩10,000 을 다르게 정할 수 있나?**
A: 가능. ASC / Play Console 에서 가격 변경 후 RC 가 자동 sync. 코드 변경 불필요. 단 변경 후 i18n 카피 (`composeExactDropPaywallPricing` + `composeExactDropBuyBtn`) 의 가격 텍스트 같이 업데이트.

**Q: 100통 외 다른 패키지 (500통 / 1000통) 추가하려면?**
A: 같은 패턴으로 새 product 등록 (`thiscount_exact_drop_500_ios` 등) → PurchaseProductIds 에 추가 → `buyExactDrop500()` 메서드 추가 → paywall 다이얼로그에 버튼 추가. 1-2시간 작업.

**Q: 신규 사용자 무료 trial 처럼 ExactDrop 도 무료 체험 가능?**
A: 현재 `exactDropFreeForBeta` flag 있음 (kDebugMode + Brand). 출시 빌드에선 무효. 신규 Brand 가입 시 무료 10통 등 grant 흐름은 `AppState.adminGrantExactDropCredits(10)` 호출만 추가하면 됨 — 별도 PR 권장.

**Q: 환불 어떻게 처리?**
A: 현재 코드는 환불 자동 차감 X. 사용자가 Apple/Google 에 환불 요청 → 받은 후 ceo@airony.xyz 로 메일 → 관리자가 Firestore 의 brandExactDropCredits 수동 감소. 후속 자동화 권장.

---

**참고**:
- 기존 4 상품 (Premium 월간 / Brand 월간 / Gift 1개월 / Brand Extra 1000) 설정 참고: [`iap-setup-guide.md`](./iap-setup-guide.md)
- 실 기기 결제 QA 체크리스트: [`real-device-purchase-qa-checklist.md`](./real-device-purchase-qa-checklist.md)
- App Store Connect paste-ready 본문: [`app-store-connect-paste-ready.md`](./app-store-connect-paste-ready.md)
- 가격 / 매출 분석: 후속 Brand 가입자 N명 × 평균 K건 ExactDrop 구매 시점에 별도 시트로 추적.
