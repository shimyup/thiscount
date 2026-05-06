# Thiscount 실기기 결제 QA 체크리스트 (배포 직전)

Last updated: 2026-04-02

적용 범위:
- iOS: App Store Sandbox (실기기)
- Android: Play Internal Testing + License Tester (실기기)

사전 조건:
- 앱은 릴리즈 빌드 설치본 사용
- RevenueCat `default` Offering에 아래 4개 상품 연결 완료
  - `letter_go_premium_monthly`
  - `letter_go_brand_monthly`
  - `letter_go_gift_1month`
  - `letter_go_brand_extra_1000`
- 테스트 계정 2개 준비
  - 일반 회원용 계정
  - Brand/Creator 계정 전환 확인용 계정

---

## 1) 공통 환경 확인 (시작 전 3분)

1. 앱 삭제 후 재설치
2. 새 계정 회원가입 또는 테스트 계정 로그인
3. `프로필 > 구독 플랜` 진입
4. 상품 카드 3종 노출 확인
   - Premium
   - Brand / Creator
   - 선물권
5. 오류 배너 노출 여부 확인
   - `상품 정보를 불러올 수 없습니다`가 뜨면 네트워크/스토어 계정/Offering 매핑부터 재확인

통과 기준:
- 3초 이내 상품 가격/버튼 노출
- 탭 시 로딩 상태 진입

---

## 2) Premium 구매 테스트

절차:
1. 일반 계정으로 로그인
2. Premium 카드의 `구독 시작 하기` 탭
3. 스토어 결제 시트 승인
4. 결제 완료 후 화면 복귀

기대 결과:
- Premium 권한 활성화
- 일일 발송 한도 Premium 기준 반영
- Premium 카드 상태가 활성 플랜으로 표시
- 오류 토스트/배너 없음

실패 시 체크:
- RevenueCat Product ID 매핑
- Offering `default` 패키지 연결
- iOS는 Sandbox 계정 로그인 상태

---

## 3) Brand 구매 테스트

절차:
1. Premium 또는 일반 계정에서 Brand 카드 `구독 시작 하기` 탭
2. 결제 승인
3. 앱 복귀 후 상태 확인

기대 결과:
- Brand 권한 활성화
- Premium 포함 혜택 동시 활성
- Brand 전용 UI(추가 발송권 영역 등) 노출
- Premium -> Brand 변경은 즉시가 아닌 예약 정책 문구/상태가 맞게 표시

실패 시 체크:
- Entitlement `brand` 연결
- 기존 구독과의 업그레이드 정책(다음 결제일 반영) 표시 로직

---

## 4) 선물권 구매 테스트

절차:
1. 선물권 카드 `구매` 탭
2. 결제 승인
3. 선물 코드/공유 UI 확인

기대 결과:
- 결제 성공 메시지 노출
- 코드 생성/공유 문자열 노출
- 다른 구독 버튼이 동시 오동작(함께 눌림)하지 않을 것

실패 시 체크:
- 버튼 터치 영역 중첩 여부
- 결제 중 중복 탭 방지 상태(`loading`/operation lock)

---

## 5) Brand 추가 발송권 구매 테스트

절차:
1. Brand 활성 계정으로 로그인
2. `추가 발송권 1,000통` 구매
3. 결제 승인

기대 결과:
- 월간 추가 쿼터 즉시 증가
- 동일 transaction 재처리 방지(중복 지급 금지)
- 실패 시 재시도 메시지 명확

실패 시 체크:
- 서버 검증 claim 문서 생성 여부
- transactionId 기준 idempotency 동작 여부

---

## 6) 구매 복원 테스트

절차:
1. 앱 재설치 또는 로그아웃/재로그인
2. `구매 복원` 탭
3. iOS의 Apple 로그인 팝업 허용

기대 결과:
- 기존 구독 권한 복원
- 복원 성공 메시지 노출
- iOS Apple 로그인 팝업은 정상 동작으로 간주

실패 시 체크:
- Store 계정이 이전 구매 계정과 동일한지
- RevenueCat customer mapping(appUserId) 일치 여부

---

## 7) 플랜 변경 정책 QA (중요)

검증 항목:
1. Free -> Premium: 가능
2. Premium -> Brand: 가능 (다음 결제일 반영 정책 표시)
3. Brand -> Premium 다운그레이드: 불가
4. Premium/Brand -> Free 다운그레이드: 예약 처리

기대 결과:
- 정책과 UI 문구가 일치
- 즉시 변경 불가 항목은 명확 안내

---

## 8) 회귀 체크 (결제 후 앱 기능)

1. 편지 발송 한도 반영
2. Premium 특급 배송 1일 3통 제한 반영
3. Brand 대량 발송/추가 발송권 반영
4. 앱 재시작 후 권한 유지
5. 로그아웃 후 재로그인 시 권한 일관성

---

## 9) 결과 기록 템플릿

| 항목 | iOS | Android | 비고 |
|---|---|---|---|
| 상품 노출 | PASS/FAIL | PASS/FAIL |  |
| Premium 구매 | PASS/FAIL | PASS/FAIL |  |
| Brand 구매 | PASS/FAIL | PASS/FAIL |  |
| 선물권 구매 | PASS/FAIL | PASS/FAIL |  |
| 추가 발송권 구매 | PASS/FAIL | PASS/FAIL |  |
| 구매 복원 | PASS/FAIL | PASS/FAIL |  |
| 플랜 변경 정책 | PASS/FAIL | PASS/FAIL |  |
| 결제 후 회귀 기능 | PASS/FAIL | PASS/FAIL |  |

릴리즈 차단 기준:
- 위 항목 중 `결제 실패`, `복원 실패`, `권한 미반영`, `중복 지급` 중 1개라도 FAIL이면 배포 보류
