# 출시 게이트 액션 패키지 (Build 463, 2026-06-13)

> **목적**: 3개월간 0 진척이던 "코드 밖 BLOCKER"를 막연한 todo → 실행 가능한 단계로 전환.
> 코드는 출시 준비 완료 상태(analyze 0 / 151 테스트 / TestFlight VALID). **남은 게이트는 전부 아래 사용자 액션뿐**이며, 이걸 끝내야 실제 출시가 됩니다. 순서는 의존성/소요시간 기준.

전부 **ceo@airony.xyz** 계정 기준(Firebase·Apple·도메인 소유 계정).

---

## ① 정적 문서 호스팅 (privacy/terms/location_terms) — 30분, 의존성 없음, **가장 먼저**
인앱 링크가 404면 App Store 심사 리젝 사유. 나머지 게이트(Privacy Label·심사)의 선행.

1. 소스: 이 레포 `docs/privacy.html`, `docs/terms.html`, `docs/location_terms.html`
2. 호스팅 레포 `shimyup/thiscount-pages`(public)에 동일 내용 push
   - 이미 `https://shimyup.github.io/thiscount-pages/{privacy,terms}.html` 운영 중 → `location_terms.html` 추가 + privacy/terms 최신본 갱신
3. 브라우저로 3개 URL 직접 열어 200 확인
4. 앱 내 설정 화면 링크(AppLinks)가 이 URL과 일치하는지 확인 (불일치 시 알려주시면 코드 수정)
- **검증 끝 = 인앱 '개인정보처리방침/이용약관/위치기반서비스 약관' 탭이 실제 페이지로 열림**

## ② 방통위 위치기반서비스사업 신고 — 행정 절차(처리 수일~), **착수만 빠를수록 좋음**
위치정보법상 위치기반서비스 사업자는 방통위 신고 의무. 미신고 운영은 법적 리스크.

1. https://www.emsit.go.kr (방송통신위원회 위치정보사업 신고 시스템) 접속
2. **위치기반서비스사업 신고**(소규모/개인사업자도 신고 대상 — 허가가 아닌 신고제) 선택
3. 준비물: 사업자등록증, 위치정보 처리 위탁/보유 현황, 서비스 개요(쿠폰 픽업), 개인정보 보호책임자(ceo@airony.xyz)
4. `docs/location_terms.html`의 필수기재(수집 항목·보유기간·제3자 제공)와 신고 내용 일치시킬 것
- **착수 = 신고서 제출 / 완료 = 신고증 수령 (출시 전 제출만 돼 있어도 리스크 큰 감소)**

## ③ 실 IAP 상품 등록 + 가격 설정 — App Store Connect, 1시간
현재 결제가 `BETA_UPGRADE_SIMULATOR`(가짜)라 실 매출 0. 구독·크레딧이 실제로 안 팔림.

1. App Store Connect(Apple ID `6766520565`) → 기능 → 구독/앱내구입. 상품은 API로 이미 생성됨(전부 draft/가격 미설정):
   - `thiscount_premium_monthly_ios` (구독)
   - `thiscount_brand_monthly_ios` (구독)
   - `thiscount_gift_1month_ios` (비소모성)
   - `thiscount_brand_extra_1000_ios` (소모성)
2. 각 상품 **가격 티어 설정** + 현지화(이름/설명) + 심사용 스크린샷
3. **RevenueCat 매핑** (project `5ba6e450`): v2 Secret API Key + Apple Shared Secret 등록 → offering에 4상품 연결. **이게 비면 앱 구독화면이 empty.**
4. 앱에서 `BETA_UPGRADE_SIMULATOR` 플래그 OFF로 실 결제 경로 전환(코드 측 — 플래그 끄는 빌드 인자, 필요 시 제가 배선)
- **완료 = 실기기에서 구독 구매 → RevenueCat webhook 200 → 크레딧/티어 반영**

## ④ App Store Privacy Label / Play Data Safety — 30분, ①+③ 후
①(문서)·③(IAP 데이터) 확정돼야 정확히 기입 가능.

1. ASC → 앱 개인정보 → 수집 데이터 유형 선언:
   - **위치**(대략적 위치 — 좌표 100m 좌표화) / **연락처 정보**(이메일·전화 OTP) / **식별자**(userId) / **구매**(IAP)
   - 각 항목 "앱 기능"·"추적 안 함"(제3자 광고 추적 없음) 명시
2. `docs/privacy.html`의 수집 항목과 **1:1 일치**시킬 것(불일치 시 리젝)
- **완료 = ASC에 라벨 저장, 심사 제출 폼 통과**

## ⑤ Auth Phase 3 cutover — 구조적 코드 BLOCKER, 실기기 의존(코드 준비는 됨)
익명 인증 IDOR(redemptionCode 평문·임의 카운터·zone 조작)의 근본. 런북 보유: `docs/AUTH_PHASE3_CUTOVER_RUNBOOK.md`.

- STEP0 authUid 룰 배포 = **완료**(2026-06-13 firestore:rules 배포에 포함)
- STEP1 `AUTH_BIND_ENABLED=true` 빌드로 그림자 바인딩 ON → STEP2 실기기 검증 → STEP3 바인딩률 95% 확인 → STEP4 rules.phase2 cutover → STEP5 모니터/롤백
- **실기기·flag·점진 배포라 자동 불가 = 사용자 영역.** ①~④ 출시 후 운영 안정화 단계에서 진행 권장(출시 자체의 P0는 아님 — 플래그 OFF 기본값이라 현 상태로 출시 가능).

---

## 권장 순서 & 병렬화
```
지금 → ① 문서 호스팅(30분)  ──┐
       ② 방통위 신고 착수    ──┼─→ ④ Privacy Label → 심사 제출
       ③ IAP+RC 매핑(1시간) ──┘
                                  ⑤ Auth Phase3 = 출시 후 운영 단계
```
- ①·②·③은 서로 독립 → 동시 진행 가능. ④는 ①③ 후. ⑤는 출시 후.
- **최소 출시 경로**: ① + ② 제출 + ③ + ④ = 약 반나절 작업 + 방통위 처리 대기. 이게 끝나면 심사 제출 가능.

## 코드 측에서 제가 추가로 할 수 있는 것 (요청 시)
- `BETA_UPGRADE_SIMULATOR` OFF 빌드 인자 배선 + 실 결제 경로 회귀 점검
- privacy.html ↔ Privacy Label 항목 대조표 생성(기입 실수 방지)
- location_terms.html 방통위 필수기재 항목 체크(누락 점검)
