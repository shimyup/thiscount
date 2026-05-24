# ASC ExactDrop 100 IAP 등록 — Step-by-Step Walkthrough

> [`exact-drop-iap-setup.md`](./exact-drop-iap-setup.md) 의 섹션 1 "App Store
> Connect" 를 화면 클릭 순서 + 필드별 정확 입력값으로 풀어 쓴 walkthrough.
> ASC 콘솔 처음 보는 사람도 따라할 수 있도록 구성.

소요 시간: **약 25~40분** (현지화 카피 14언어 입력 포함 시).

---

## 0. 시작 전 사전 체크리스트

ASC 에서 IAP product 등록을 시작하려면 **반드시 4가지가 활성** 되어 있어야 합니다. 빠지면 등록 단계에서 막힘.

| 항목 | 확인 위치 | 상태 |
|---|---|---|
| Apple Developer Program 멤버십 활성 | https://developer.apple.com/account → 회원 정보 | "Active" |
| Paid Applications Agreement | ASC → 비즈니스 → 계약, 세금 및 금융 거래 | "활성" |
| 세금 정보 입력 완료 | 동일 메뉴 → 세금 양식 | W-8BEN-E (해외) 또는 한국 사업자등록번호 |
| 은행 계좌 검증 완료 | 동일 메뉴 → 은행 정보 | "확인됨" + micro-deposit 검증 완료 |

❌ 이 중 하나라도 미완성이면 IAP 메뉴 자체가 ASC 에 나타나지 않거나 "+" 버튼 비활성.

✅ 모두 완료 후 다음 단계 진행.

---

## 1. ASC 접속 + 앱 선택

### 1.1 로그인
1. https://appstoreconnect.apple.com 접속
2. Apple ID (Airony company inc. 계정) 로 로그인
3. 2단계 인증 코드 입력

### 1.2 앱 선택
1. 상단 메뉴 **"앱"** 클릭
2. 앱 목록에서 **"Thiscount"** 클릭 (또는 검색)
3. 앱 상세 페이지 진입

### 1.3 인앱 구매 메뉴 진입
1. 좌측 사이드바 **"수익화"** 섹션 펼침
2. 그 아래 **"인앱 구매"** 클릭
3. 현재 등록된 IAP 목록 페이지 진입 (기존 4 상품 확인 가능)
   - thiscount_premium_monthly_ios
   - thiscount_brand_monthly_ios
   - thiscount_gift_1month_ios
   - thiscount_brand_extra_1000_ios

> 메뉴가 안 보이면 → 0번 사전 체크 다시 확인.

---

## 2. 신규 IAP 생성

### 2.1 "+" 버튼 클릭
인앱 구매 목록 페이지 좌측 상단 **파란 "+" 버튼** 클릭.

### 2.2 IAP 유형 선택 모달
모달에서 4가지 유형 표시:

| 유형 | 설명 | 이번 선택 |
|---|---|---|
| 자동 갱신 구독 | 매월·매년 자동 결제 (Premium / Brand 월간) | ❌ |
| 비갱신 구독 | 기간 한정, 자동 갱신 X | ❌ |
| 비소모성 | 1회 구매 후 영구 사용 (광고 제거 등) | ❌ |
| **소모성** | 사용 후 소진 → 재구매 가능 (게임 아이템·크레딧) | ✅ **선택** |

**"소모성"** 클릭 → "생성" 버튼 클릭.

> 왜 소모성? — ExactDrop credit 은 발송 시 1 차감되는 게임 화폐 패턴. 100통 다 쓰면 다시 구매. 영구 보유 아니라 소모성 정답.

---

## 3. 기본 정보 입력

### 3.1 참조 이름 (Reference Name)
- 입력 칸: **"참조 이름"** 또는 **"Reference Name"**
- 값: `ExactDrop 100 Package`
- 용도: 콘솔 내부 식별용 (사용자 안 봄, ASC 직원·관리자가 봄)
- 규칙: 한글 가능, 64자 이내, 변경 가능

### 3.2 제품 ID (Product ID)
- 입력 칸: **"제품 ID"** 또는 **"Product ID"**
- 값: **`thiscount_exact_drop_100_ios`** ⚠️ **정확히 일치**
- 규칙:
  - 영문 소문자 + 숫자 + 밑줄(_) + 점(.) 만 가능
  - **한 번 등록 후 변경 불가** — 오타 시 상품 삭제하고 새로 만들어야 함
  - 같은 앱 안에서 unique
- 왜 이 ID? — `lib/core/services/purchase_service.dart:50` 의 `_exactDrop100Ios` 와 정확히 일치해야 RC 가 매핑.

> ⚠️ 입력 후 화면 우측 상단 **"저장"** 클릭. ID 가 회색 처리되며 변경 불가 상태가 됨.

---

## 4. 가격 책정

### 4.1 "가격 책정" 탭 진입
좌측 사이드바 (상품 페이지 내) **"가격 책정"** 클릭.

### 4.2 가격 일정 추가
1. **"+가격 추가"** 버튼 클릭
2. 모달에서:
   - **시작일**: "즉시" 또는 출시 예정일
   - **종료일**: "종료 없음"
   - **기본 국가**: "대한민국"
   - **기본 가격**: **티어 10 (₩10,000)** 선택

### 4.3 가격 매트릭스 확인
"가격 매트릭스" 표시 → 다른 국가별 자동 환율 적용 가격 노출:
- 미국: $7.99
- 일본: ¥1,200
- 중국: ¥69
- 유럽: €7.99
- 영국: £7.49

> 자동 가격이 마음에 안 들면 국가별로 **개별 가격 재설정** 가능 (선택). 기본은 자동 환율 권장.

### 4.4 가용성 (Availability)
- 좌측 사이드바 **"앱 가용성"** 또는 가격 페이지 하단 **"가용 지역"** 확인
- 기본값: "모든 지역" — 보통 그대로 두면 됨
- 특정 국가만 출시하려면 **"선택 지역만"** → 체크박스로 KR/JP/US 등 선택

### 4.5 저장
우측 상단 **"저장"** 버튼 → 가격 정보 적용.

---

## 5. App Store 정보 — 한국어 현지화 (필수)

ASC 는 IAP product 마다 **앱이 출시된 모든 언어에 현지화 필수**. 한국 출시면 최소 한국어, 영어 출시면 영어.

### 5.1 "App Store 정보" 또는 "현지화" 탭 진입
좌측 사이드바 **"App Store 정보"** 클릭 → **"현지화"** 섹션.

### 5.2 한국어 추가
1. **"+ 언어 추가"** 클릭
2. 드롭다운에서 **"한국어"** 선택
3. 빈 폼 노출 → 아래 값 정확히 입력:

```
표시 이름: ExactDrop 크레딧 100통

설명: 원하는 매장·좌표에 정확히 100통의 혜택을 뿌릴 수 있어요. 1회 구매 시 100통 자동 충전, 사용 시 1통씩 차감됩니다.
```

**길이 제한**:
- 표시 이름: 30자 이내 → "ExactDrop 크레딧 100통" = 17자 ✅
- 설명: 45자 이상 ~ 4000자 이내 → 위 본문 = ~60자 ✅

### 5.3 저장
우측 상단 **"저장"** → 한국어 현지화 추가 완료.

---

## 6. App Store 정보 — 영어 현지화 (필수)

### 6.1 영어 추가
1. **"+ 언어 추가"** 클릭
2. **"English (U.S.)"** 선택
3. 입력:

```
Display Name: ExactDrop 100 Credits

Description: Drop 100 promos on exact store locations or coordinates. One-time purchase adds 100 credits instantly. Each ExactDrop send consumes 1 credit.
```

길이: Display Name 18자 ✅ / Description 175자 ✅

### 6.2 저장

---

## 7. App Store 정보 — 추가 12언어 (선택이나 권장)

앱이 14언어 (ko/en/ja/zh/fr/de/es/pt/ru/tr/ar/it/hi/th) 로 출시되어 있다면 모든 현지화 추가가 깔끔. 미입력 시 영어 fallback.

### 7.1 일본어 (ja)
```
表示名: ExactDrop 100クレジット

説明: 店舗や正確な座標に100通の特典を配信。購入で100クレジット即時追加、送信時に1クレジットずつ消費されます。
```

### 7.2 중국어 (zh, 간체)
```
显示名称: ExactDrop 100次额度

描述: 精确投放100次优惠到指定地点或坐标。购买后立即获得100额度，每次发送消耗1次。
```

### 7.3 프랑스어 (fr)
```
Nom: ExactDrop 100 Crédits

Description: Déposez 100 récompenses à des emplacements précis. Achat unique = +100 crédits, 1 crédit consommé par envoi.
```

### 7.4 독일어 (de)
```
Name: ExactDrop 100 Credits

Beschreibung: 100 Belohnungen an exakten Orten platzieren. Einmaliger Kauf = +100 Credits, 1 Credit pro Versand.
```

### 7.5 스페인어 (es)
```
Nombre: ExactDrop 100 Créditos

Descripción: Deja 100 recompensas en ubicaciones exactas. Compra única = +100 créditos, 1 por envío.
```

### 7.6 포르투갈어 (pt)
```
Nome: ExactDrop 100 Créditos

Descrição: Deixe 100 recompensas em locais exatos. Compra única = +100 créditos, 1 por envio.
```

### 7.7 러시아어 (ru)
```
Название: ExactDrop 100 кредитов

Описание: Размещайте 100 наград в точных местах. Разовая покупка = +100 кредитов, 1 на отправку.
```

### 7.8 터키어 (tr)
```
Ad: ExactDrop 100 Kredi

Açıklama: 100 ödülü tam konumlara yerleştirin. Tek satın alım = +100 kredi, gönderim başına 1 kredi.
```

### 7.9 아랍어 (ar)
```
الاسم: ExactDrop 100 رصيد

الوصف: ضع 100 مكافأة في مواقع دقيقة. شراء واحد = +100 رصيد، 1 رصيد لكل إرسال.
```

### 7.10 이탈리아어 (it)
```
Nome: ExactDrop 100 Crediti

Descrizione: Rilascia 100 ricompense in luoghi esatti. Acquisto unico = +100 crediti, 1 per invio.
```

### 7.11 힌디어 (hi)
```
नाम: ExactDrop 100 क्रेडिट

विवरण: 100 पुरस्कारों को सटीक स्थानों पर रखें। एक बार खरीद = +100 क्रेडिट, प्रति भेजने पर 1 क्रेडिट।
```

### 7.12 태국어 (th)
```
ชื่อ: ExactDrop 100 เครดิต

คำอธิบาย: วาง 100 รางวัลที่ตำแหน่งที่แม่นยำ ซื้อครั้งเดียว = +100 เครดิต ใช้ 1 เครดิตต่อการส่ง
```

---

## 8. 심사용 스크린샷

### 8.1 요구 사항
- 해상도: **1284 × 2778** (iPhone 14 Pro Max / 15 Pro Max 기준) 또는 1242 × 2208 (legacy)
- 형식: PNG, RGB, sRGB
- 파일 크기: 최대 10MB
- 1장 이상 필수 (보통 1장만 등록)

### 8.2 캡처 시점
TestFlight 빌드 (Build 324+) 에서:

1. **Brand 계정으로 로그인** (Brand 인증 완료 상태)
2. `/compose` 화면 진입 (중앙 보내기 탭 → "📣 캠페인")
3. compose 화면 하단의 **"🏢 브랜드 옵션"** 섹션 펼치기
4. **시나리오 칩 3개** 중 **"🎯 정확 좌표 단건"** 탭
5. ExactDrop paywall 다이얼로그 노출 ← 여기서 캡처
6. 다이얼로그 내용:
   - 제목: "🎯 정확 좌표 드롭은 유료 기능이에요"
   - 본문: "원하는 매장·좌표에 혜택을 정확히 뿌릴 수 있어요..."
   - 가격 카드: "💰 100통 패키지 · 10,000원"
   - 하단 버튼: **"100통 구매 (₩10,000)"** (gold 색)

### 8.3 캡처 방법
**iOS Simulator**:
1. Xcode 실행 → Simulator (iPhone 14 Pro Max)
2. 앱 실행 → 위 시나리오 따라가기
3. `Cmd + S` → 스크린샷 데스크탑 저장
4. 해상도 확인 (Preview 로 열기 → Tools → Inspector)

**실 기기**:
1. iPhone 에서 위 시나리오 따라가기
2. 사이드 버튼 + 볼륨업 동시 누르기 → 스크린샷
3. 사진 앱 → AirDrop 또는 USB 로 Mac 으로 전송

### 8.4 저장 + 업로드
1. 파일명: `exact_drop_100_paywall.png`
2. 저장 위치: `docs/release/iap_screenshot_guides/exact_drop_100_paywall.png` (Git 트래킹)
3. ASC IAP 페이지 좌측 사이드바 **"App Store 정보"** → **"App Store 프로모션"** 또는 **"스크린샷"** 섹션 → "스크린샷 추가" → 위 파일 업로드

---

## 9. 심사용 검토 메모 (Review Notes)

### 9.1 위치
좌측 사이드바 **"App Store 정보"** → 페이지 하단 **"검토 정보"** 섹션 → **"검토 노트"** 칸.

### 9.2 본문 (paste-ready)

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
2. The center bottom-nav tab will display "📣 Campaign" (Brand role)
3. Tap it to enter the compose screen
4. Scroll down to the "🏢 Brand options" section
5. Three scenario chips appear: "📍 Around my store", "🎯 Exact location",
   "🌍 Global bulk"
6. Tap "🎯 Exact location"
7. Since the account starts with 0 ExactDrop credits, the paywall dialog
   appears with the title "🎯 Exact-coordinate drop is a paid feature"
8. The dialog contains a price card showing "100-promo package · KRW 10,000"
   and a "Buy 100 promos (₩10,000)" button at the bottom (gold color)
9. Tapping the button triggers the Apple StoreKit payment sheet
10. After successful sandbox purchase, the credit balance updates to 100
    and the ExactDrop map selector opens automatically

== AGE RATING ==
4+ — same as the main app. No new content categories introduced.

== PRICING ==
KRW 10,000 (~ USD $7.99), one-time consumable, no recurring charges.
Refunds are processed via standard App Store refund flow.

== DATA COLLECTION ==
Purchase events are tracked via RevenueCat for revenue analytics.
No additional PII collected beyond what the main app already collects.
```

### 9.3 저장
우측 상단 **"저장"** → 검토 메모 등록 완료.

---

## 10. 상태 확인 + 제출 준비 완료

### 10.1 상태 표시 확인
상품 상세 페이지 우측 상단에 상태 배지 표시:

| 상태 | 의미 | 다음 단계 |
|---|---|---|
| **"제출 준비 완료"** 🟢 | 모든 메타데이터 입력 완료, 빌드 제출 시 IAP 도 함께 심사 | 빌드 제출 (12번 단계) |
| **"메타데이터 누락"** 🔴 | 필수 필드 비어 있음 | 빨간 배너 클릭 → 누락 필드 보고 채움 |
| **"심사 진행 중"** 🟡 | 빌드 제출 후 심사 중 | 대기 (24-48h) |
| **"승인됨"** ✅ | 심사 통과, 출시 가능 | 출시 빌드에 포함 |
| **"거부됨"** ❌ | Apple 거부 사유 표시 | 사유 확인 후 수정 |

### 10.2 누락 시 흔한 원인
- 한국어 또는 영어 현지화 비어 있음
- 가격 미설정
- 스크린샷 미업로드
- 검토 메모 빈칸

### 10.3 모두 완료 후
**"제출 준비 완료"** 표시 확인 → ASC 작업 끝.

---

## 11. 다음 단계 안내

ASC IAP 등록은 끝났지만 실제 사용자가 구매하려면 다음 3 단계 필요:

### 11.1 Google Play Console (Android)
별도 가이드: [`exact-drop-iap-setup.md` 섹션 2](./exact-drop-iap-setup.md#2-google-play-console-android)

### 11.2 RevenueCat Dashboard
- Products 탭 → iOS / Android 2개 등록
- Offerings 탭 → `default` offering 에 `exact_drop_100` package 추가
- 별도 가이드: [`exact-drop-iap-setup.md` 섹션 3](./exact-drop-iap-setup.md#3-revenuecat-dashboard)

### 11.3 다음 빌드 제출 시 IAP 체크
- ASC → 앱 → 새 버전 (예: 1.0.0 (325)) 에서 **"인앱 구매"** 섹션
- 기존 4개 + 신규 1개 (ExactDrop 100) 총 5개 체크박스 모두 선택
- 심사 제출

---

## 12. Sandbox 테스트 (출시 전 필수)

자세한 검증: [`exact-drop-iap-setup.md` 섹션 4](./exact-drop-iap-setup.md#4-sandbox-테스트-출시-전-필수)

핵심:
1. ASC → 사용자 및 액세스 → 샌드박스 사용자 → 신규 sandbox Apple ID 생성
2. iPhone 설정 → App Store → 샌드박스 계정 로그인
3. TestFlight 빌드 설치 → Brand 계정 → compose → 🎯 시나리오 칩 → "100통 구매" 버튼
4. Apple 결제 sheet 떠야 함 + "샌드박스 결제" 빨간 배너
5. 결제 완료 후 balance 100 확인

---

## 13. 자주 헷갈리는 부분

### Q1. "+" 버튼이 회색이라 클릭 안 됨
**A**: 0번 사전 체크 미완성. Paid Apps Agreement 가 가장 흔한 원인.

### Q2. 제품 ID 입력 후 "이미 존재합니다" 에러
**A**: 이전에 같은 ID 로 등록 후 삭제한 경우. Apple 은 삭제된 ID 재사용 차단.
해결: `thiscount_exact_drop_100_v2_ios` 같이 변경 + `lib/core/services/purchase_service.dart` 의 `_exactDrop100Ios` 도 같이 변경.

### Q3. 현지화 14언어 다 입력해야 하나?
**A**: 앱이 출시된 언어만 필수. 13언어 출시면 13개 모두 입력 필요. 영어 fallback 가능하지만 사용자 경험 위해 모두 입력 권장.

### Q4. 가격 변경하려면?
**A**: 등록 후에도 가격 변경 가능. "가격 책정" 탭 → "+가격 추가" → 새 시작일 + 새 티어 선택. 기존 사용자는 영향 없음.

### Q5. 출시 전 미리 sandbox 테스트하고 싶음
**A**: ASC IAP 가 "제출 준비 완료" 상태면 sandbox 테스트 가능. 심사 승인 전에도 가능 (단 production user 는 못 봄).

### Q6. 심사 거부 후 재제출
**A**: 거부 사유 확인 → 수정 → 같은 IAP product 페이지에서 다시 저장 → 다음 빌드 제출 시 자동 재심사. 별도 작업 X.

### Q7. 가격 환율 자동이 너무 부자연스러움 (예: ¥1199.50)
**A**: 국가별 개별 가격 설정 가능. 예: 일본만 ¥1200 으로 round.

---

## 14. 체크리스트 (인쇄 / 따라하기)

ASC 콘솔에서 진행하면서 체크:

- [ ] **0**. Paid Apps Agreement 활성 확인
- [ ] **1.1**. ASC 로그인 → 앱 → Thiscount → 인앱 구매 메뉴
- [ ] **2.1-2.2**. "+" 버튼 → 소모성 선택
- [ ] **3.1**. 참조 이름 `ExactDrop 100 Package`
- [ ] **3.2**. 제품 ID `thiscount_exact_drop_100_ios` ⚠️
- [ ] **4.2**. 기본 가격 티어 10 (₩10,000)
- [ ] **4.4**. 가용 지역 확인
- [ ] **5.2**. 한국어 표시 이름 + 설명 입력
- [ ] **6.1**. 영어 표시 이름 + 설명 입력
- [ ] **7.x**. 추가 12언어 입력 (선택)
- [ ] **8.4**. 스크린샷 1장 업로드
- [ ] **9.2**. 영문 검토 메모 입력
- [ ] **10.1**. 상태 = "제출 준비 완료" 🟢 확인
- [ ] **11.1**. Play Console 작업 진행
- [ ] **11.2**. RevenueCat 매핑 진행
- [ ] **12**. Sandbox 테스트 통과
- [ ] **11.3**. 다음 빌드 제출 시 IAP 체크박스 활성

---

**참고 파일**:
- [`exact-drop-iap-setup.md`](./exact-drop-iap-setup.md) — 전체 콘솔 작업 (Play Console + RevenueCat 포함)
- [`iap-setup-guide.md`](./iap-setup-guide.md) — 기존 4 상품 설정 (참고용)
- [`real-device-purchase-qa-checklist.md`](./real-device-purchase-qa-checklist.md) — 실 기기 결제 QA

**문의**: 콘솔 작업 중 막힘 → ceo@airony.xyz
