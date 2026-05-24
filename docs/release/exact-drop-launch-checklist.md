# ExactDrop 100 IAP 출시 체크리스트 — 따라하기

> 사용자가 "이미지 캡쳐하고 나머지 진행 도와줘" 라는 요청에 대한 단계별
> next-action 가이드. 각 단계마다 **명령어 / 클릭 흐름 / 확인 방법** 명시.
>
> 총 소요 시간: **2-4시간** (콘솔 입력 + sandbox 테스트 + 빌드 제출 + 심사 대기 제외).

---

## ✅ Step 0 — 코드 사이드 완료 확인 (이미 끝남)

- [x] PR #61 에 21 commit 머지 대기
- [x] Build 324 코드 (ExactDrop IAP 구매 흐름)
- [x] paywall 카피 14언어
- [x] mockup PNG 3개 (ko/en/ja) 자동 생성

빠진 게 있으면 [`exact-drop-iap-setup.md`](./exact-drop-iap-setup.md) 와 [`exact-drop-iap-asc-walkthrough.md`](./exact-drop-iap-asc-walkthrough.md) 참조.

---

## ✅ Step 1 — paywall mockup PNG 확보 (자동)

```bash
cd ~/Documents/New\ project/Lettergo
python3 scripts/generate_exact_drop_paywall_mockup.py --all
```

출력:
- `docs/release/iap_screenshot_guides/exact_drop_100_paywall.png` (ko)
- `docs/release/iap_screenshot_guides/exact_drop_100_paywall_en.png`
- `docs/release/iap_screenshot_guides/exact_drop_100_paywall_ja.png`

**검증**:
```bash
ls -la docs/release/iap_screenshot_guides/exact_drop_100_paywall*.png
# 3개 파일 ~100-130 KB 각각 확인
```

이 mockup 으로 ASC 1차 등록 → 추후 sandbox 실 캡처로 교체 가능.

---

## 🟡 Step 2 — App Store Connect IAP 등록 (수동, 25-40분)

### 2.1 ASC 접속
1. https://appstoreconnect.apple.com → Apple ID 로그인 (Airony 계정)
2. 앱 → **Thiscount** → 좌측 **수익화** → **인앱 구매**

### 2.2 신규 IAP 생성
1. 좌측 상단 **"+"** 버튼 → **소모성** 선택 → "생성"
2. 필드 입력:
   ```
   참조 이름: ExactDrop 100 Package
   제품 ID:  thiscount_exact_drop_100_ios   ⚠️ 정확히
   ```
3. **저장** 클릭

### 2.3 가격 책정
- 좌측 사이드바 **"가격 책정"** → "+가격 추가"
- 시작일: "즉시" / 종료: "종료 없음"
- 기본 가격: **티어 10 (₩10,000)**
- 저장

### 2.4 현지화 추가 (한국어 + 영어 필수)

**한국어 (paste-ready)**:
```
표시 이름:
ExactDrop 크레딧 100통

설명:
원하는 매장·좌표에 정확히 100통의 혜택을 뿌릴 수 있어요. 1회 구매 시 100통 자동 충전, 사용 시 1통씩 차감됩니다.
```

**영어 (paste-ready)**:
```
Display Name:
ExactDrop 100 Credits

Description:
Drop 100 promos on exact store locations or coordinates. One-time purchase adds 100 credits instantly. Each ExactDrop send consumes 1 credit.
```

**추가 12언어** (선택, 권장): [`exact-drop-iap-asc-walkthrough.md` 섹션 7](./exact-drop-iap-asc-walkthrough.md#7-app-store-정보--추가-12언어-선택이나-권장) 의 paste-ready 본문 사용.

### 2.5 스크린샷 업로드
- 좌측 사이드바 **"App Store 정보"** → 스크린샷 섹션
- 업로드: `docs/release/iap_screenshot_guides/exact_drop_100_paywall.png`
  - Mockup PNG 사이즈 (1284 × 2778) ✅
  - 형식 PNG ✅
  - 크기 ~100 KB ✅

### 2.6 검토 메모 (paste-ready 영문)

좌측 사이드바 **"App Store 정보"** → 페이지 하단 **"검토 노트"** 칸:

```
ExactDrop is a Brand-tier only feature that allows verified business owners
to drop promotional offers (coupons, vouchers) on exact map coordinates
(precise pin location) rather than relying on random city-wide distribution.

The "ExactDrop 100 Credits" is a one-time consumable in-app purchase that
adds 100 ExactDrop credits to the Brand account's balance. Each precise-
location drop consumes 1 credit. There are no subscriptions, no recurring
charges, and credits never expire.

== HOW TO TEST ==

Test account credentials (Brand-tier verified):
- Email: qa-brand-2026@thiscount.io
- Password: [Provided separately via App Review Information]

Steps to reach the IAP:
1. Launch the app and log in with the test account above
2. The center bottom-nav tab will display "Campaign" (Brand role)
3. Tap it to enter the compose screen
4. Scroll down to the "Brand options" section
5. Three scenario chips appear: "Around my store", "Exact location",
   "Global bulk"
6. Tap "Exact location"
7. Since the account starts with 0 ExactDrop credits, the paywall dialog
   appears with a "Buy 100 promos (KRW 10,000)" button at the bottom
8. Tapping the button triggers the Apple StoreKit payment sheet
9. After successful sandbox purchase, the credit balance updates to 100
   and the ExactDrop map selector opens automatically

== AGE RATING ==
4+ — same as the main app. No new content categories introduced.

== PRICING ==
KRW 10,000 (~ USD $7.99), one-time consumable, no recurring charges.
```

### 2.7 상태 확인
- 우측 상단 **"제출 준비 완료"** 🟢 표시 확인
- 빨강 "메타데이터 누락" 이면 누락 필드 채움

---

## 🟡 Step 3 — Google Play Console IAP 등록 (수동, 15분)

### 3.1 Play Console 접속
1. https://play.google.com/console → 로그인
2. 앱 → **Thiscount** → 좌측 **수익화** → **앱 내 상품**

### 3.2 신규 상품 생성
1. 우측 **"상품 만들기"**
2. 필드:
   ```
   제품 ID:  letter_go_exact_drop_100   ⚠️ 정확히 (legacy prefix 유지)
   이름:    ExactDrop 크레딧 100통
   설명:    원하는 매장·좌표에 정확히 100통의 혜택을 뿌릴 수 있어요.
   기본 가격: ₩10,000
   상태:    활성
   ```
3. "+가격 자동 적용" 체크 → 다른 국가 자동 환율
4. 저장

### 3.3 라이선스 테스터 추가
- 설정 → **라이선스 테스트** → 테스터 Gmail 추가 (sandbox 결제 가능 계정)

---

## 🟡 Step 4 — RevenueCat 매핑 (수동, 10분)

### 4.1 https://app.revenuecat.com → 프로젝트 (Thiscount)

### 4.2 Products 등록
**Products** 탭 → "+ New" 2개:

| Display name | Store ID | Type | Store |
|---|---|---|---|
| ExactDrop 100 (iOS) | `thiscount_exact_drop_100_ios` | Non-Subscription | App Store |
| ExactDrop 100 (Android) | `letter_go_exact_drop_100` | Non-Subscription | Play Store |

### 4.3 Offerings 추가
**Offerings** 탭 → `default` offering → "Add package":

| Package ID | Product (iOS) | Product (Android) |
|---|---|---|
| `exact_drop_100` | `thiscount_exact_drop_100_ios` | `letter_go_exact_drop_100` |

⚠️ Entitlement 매핑 X — consumable 이라 entitlement 불필요.

---

## 🟡 Step 5 — Sandbox 테스트 (수동, 20분)

### 5.1 iOS Sandbox

**Sandbox Apple ID 생성**:
1. ASC → 사용자 및 액세스 → **샌드박스 사용자** → "+"
2. 가짜 이메일 (예: `qa-exact-drop-2026@test.com`) + 비번
3. 저장

**iPhone Simulator 또는 실 기기에서**:
1. 설정 → **App Store** → 하단 **샌드박스 계정** → 위 Apple ID 로그인
2. TestFlight 빌드 (Build 324+) 설치
3. **Brand 계정**으로 앱 로그인
4. compose → 🎯 "정확 좌표 단건" 칩 → paywall
5. **"100통 구매 (₩10,000)"** 버튼 탭
6. Apple 결제 sheet 확인 (sandbox 빨강 배너) → 결제 완료
7. 자동으로 ExactDrop 진입 → balance 100 확인

**또는 자동 캡처 script**:
```bash
./scripts/capture_exact_drop_paywall_from_simulator.sh
```
(수동 paywall 진입 단계 안내 → 화면 보이면 Enter)

### 5.2 Android Sandbox

1. 라이선스 테스터 Gmail 로 로그인된 Android
2. TestFlight 또는 internal track 빌드 설치
3. 위 5.1 과 동일한 흐름

### 5.3 검증 체크리스트
- [ ] paywall 다이얼로그의 "100통 구매" gold 버튼 보임
- [ ] 탭 시 Apple/Google 결제 sheet 떠짐
- [ ] sandbox 배너 확인
- [ ] 결제 완료 후 SnackBar `🎯 ExactDrop +100 (100)`
- [ ] 자동으로 ExactDrop 핀 선택 진입
- [ ] `brandExactDropCredits` = 100
- [ ] 다음 발송 시 1 차감 (99)
- [ ] 0 까지 사용 후 다시 paywall (재구매)
- [ ] 앱 재시작 후 credit 잔량 유지
- [ ] 다른 디바이스 로그인 시 server 복원

### 5.4 실 sandbox 캡처 → ASC 교체 (권장)
sandbox 캡처가 mockup 보다 정확. ASC 의 스크린샷을 sandbox 캡처로 교체:
```bash
xcrun simctl io booted screenshot ~/Desktop/exact_drop_paywall_real.png
```
→ ASC IAP 페이지 → 기존 mockup 제거 → 새 PNG 업로드.

---

## 🟢 Step 6 — 빌드 제출 (자동 script)

### 6.1 코드 정리 + 빌드
```bash
cd ~/Documents/New\ project/Lettergo

# 1. pubspec.yaml 버전 확인 (1.0.0+324 또는 그 이상)
grep "^version:" pubspec.yaml

# 2. flutter analyze + test
flutter analyze
flutter test

# 3. TestFlight 자동 빌드 + 업로드
./scripts/release_to_testflight.sh
```

### 6.2 ASC 에서 빌드 → 새 버전 생성
1. ASC → 앱 → Thiscount → 좌측 **"버전 정보"**
2. **"+ 버전 또는 플랫폼"** → 새 버전 (예: `1.0.0`)
3. 빌드 섹션 → 방금 업로드한 빌드 선택
4. **"인앱 구매"** 섹션 → 5개 상품 모두 체크 (기존 4 + ExactDrop 100)
5. 출시 노트 + 스크린샷 입력
6. **"심사를 위해 제출"**

심사 대기: 24-48h (보통 12h).

---

## 🟢 Step 7 — 출시 후 모니터링

### 7.1 RevenueCat Dashboard
https://app.revenuecat.com → Charts → "Revenue" → ExactDrop transaction 확인.

### 7.2 Firestore 검증
```bash
# Brand 사용자 1명 sample 확인
firebase firestore:get users/{user_id} --project thiscount-prod
# brandExactDropCredits 필드가 100 또는 그 이상인지
```

### 7.3 App Store / Play Console 매출 보고서
- ASC → 매출 → 일별 차트에서 `thiscount_exact_drop_100_ios` transaction count
- Play Console → 수익 → 동일

---

## 🆘 트러블슈팅

| 증상 | 원인 | 해결 |
|---|---|---|
| ASC 에서 IAP "+" 버튼 회색 | Paid Apps Agreement 미체결 | 비즈니스 → 계약/세금/은행 검증 |
| 제품 ID "이미 존재" 에러 | 이전 등록 후 삭제됨 (Apple 재사용 차단) | ID 변경 (`v2` suffix) + 코드 `_exactDrop100Ios` 도 변경 |
| sandbox 결제 sheet 안 뜸 | sandbox Apple ID 로그인 안 됨 | 설정 → App Store → 샌드박스 계정 |
| 결제 완료해도 credit 안 늘어남 | RC offering 미매핑 | Step 4 다시 |
| "Offering not found" 디버그 로그 | `default` offering "Current" 미설정 | RC dashboard 에서 "Make Current" 클릭 |
| Mockup PNG 의 emoji 가 □ 박스 | Pillow Apple Color Emoji 미지원 | Step 5.4 의 sandbox 실 캡처로 교체 |
| Simulator 자동 캡처 script 실패 | flutter doctor 통과 안 됨 / xcrun 권한 | `flutter doctor -v` + `sudo xcode-select --reset` |

---

## 📊 진행 요약

| Step | 시간 | 자동? | 의존 |
|---|---|---|---|
| 0. 코드 사이드 | 완료 | - | - |
| 1. Mockup PNG | 5초 | ✅ Python script | Pillow |
| 2. ASC IAP 등록 | 25-40분 | ❌ 수동 | Apple Dev 계정 |
| 3. Play Console IAP 등록 | 15분 | ❌ 수동 | Play 계정 |
| 4. RevenueCat 매핑 | 10분 | ❌ 수동 | RC 계정 |
| 5. Sandbox 테스트 | 20분 | 🟡 반자동 (script + 수동 클릭) | Xcode + Sandbox Apple ID |
| 6. 빌드 제출 | 5분 + 12-48h 심사 대기 | ✅ Shell script | TestFlight 셋업 |
| 7. 출시 모니터링 | 지속 | - | - |

**총 active 시간: 약 2시간** (심사 대기 제외).

---

## 📎 관련 문서

- [`exact-drop-iap-setup.md`](./exact-drop-iap-setup.md) — 전체 콘솔 작업 (9 섹션)
- [`exact-drop-iap-asc-walkthrough.md`](./exact-drop-iap-asc-walkthrough.md) — ASC 14단계 walkthrough
- [`iap-setup-guide.md`](./iap-setup-guide.md) — 기존 4 상품 (참고)
- [`real-device-purchase-qa-checklist.md`](./real-device-purchase-qa-checklist.md) — 실 기기 QA

**막힘 신고**: 콘솔 작업 중 막힘 → 스크린샷 + 단계 번호로 알려주세요.
