# 위치기반 앱 출시 점검 — Thiscount (Build 410)

생성: 2026-05-30. 코드베이스 audit + 위치정보법/플랫폼 정책 기준. **법률 자문 아님 — 신고·약관은 변호사/노무사 검토 권장.**

---

## A. 유의점 (위치기반 앱 출시 핵심)

### 1. 한국 위치정보법 (가장 중요 · 다른 체크리스트가 놓치는 부분)
"위치정보의 보호 및 이용 등에 관한 법률" — 개인위치정보를 이용하는 서비스는 **방송통신위원회에 위치기반서비스사업 신고** 의무.
- **신고 대상**: 위치정보사업자(통신사/GPS 제공자)로부터 위치정보를 받아 서비스 제공 = 위치기반서비스사업자 → **신고제**(허가 아님). 본 앱은 기기 GPS만 사용해 "근처 쿠폰" 제공 → 위치기반서비스사업자에 해당.
- **소상공인/1인 창조기업 간소화 신고** 가능 (lbsc.kr).
- **접수**: 전자민원센터 emsit.go.kr 온라인. 별지 제6호 신고서 + 사업계획서 + 사업자등록증.
- **위반**: 미신고 영업 = 형사처벌(3년 이하 징역/3천만원 이하 벌금) 가능.
- **위치기반서비스 이용약관 별도 작성 의무** (개인정보처리방침과 별개). 미명시 = 1천만원 이하 과태료.

### 2. 개인정보보호 (PIPA/GDPR)
- 위치정보는 민감 → **별도·명시적 동의**, 최소수집, 보유기간 명시, 파기.
- EU 사용자(14언어 = 글로벌) → GDPR: 동의 철회·열람·삭제·이동권.
- 만 14세 미만(KR) / 13세 미만(COPPA) 차단 또는 법정대리인 동의.

### 3. 플랫폼 정책
- **App Store 5.1.1**: 위치 사용 목적 문자열 필수, 포그라운드만 사용 권장, 계정 삭제 in-app 제공 의무.
- **Google Play**: 백그라운드 위치 사용 시 별도 선언 + prominent disclosure + 심사. Data Safety form.
- 양쪽 모두 Privacy Label / Data Safety form 제출.

---

## B. 필요 서류 / 제출물

| # | 서류 | 대상 | 본 앱 상태 |
|---|------|------|-----------|
| B1 | **위치기반서비스사업 신고서** (별지6호) + 사업계획서 + 사업자등록증 | 방통위(emsit.go.kr) | ❌ 미신고 (업무·법률 영역) |
| B2 | **위치기반서비스 이용약관** (별도 문서) | 앱 내 + 약관 페이지 | ❌ 없음 (개인정보방침에 포함됨) |
| B3 | 개인정보처리방침 (위치 항목 포함) | 앱 내 + 웹 호스팅 | ⚠️ 작성됨(docs/privacy.html) 但 thiscount.io 미호스팅 |
| B4 | 서비스 이용약관 (terms) | 앱 내 + 웹 | ⚠️ 동일 (호스팅 확인 필요) |
| B5 | App Store Privacy Nutrition Label | ASC 제출 | ✅ PrivacyInfo.xcprivacy 작성됨 |
| B6 | Play Data Safety form | Play Console | ⚠️ 데이터 목록 docs/security/privacy-disclosures.md 준비됨 → 폼 입력 필요 |

**B2 위치기반서비스 이용약관 필수 기재사항**: 상호·주소·연락처 / 개인위치정보주체·법정대리인의 권리와 행사방법 / 제공 서비스 내용 / 위치정보 수집사실 확인자료 보유근거·기간 / 보유목적·기간 / 동의 철회 방법 / (제3자 제공 시) 제공받는 자·일시·목적 즉시 통보.

---

## C. 필요 기능 (위치정보법 + 플랫폼)

| # | 기능 | 본 앱 상태 (file) |
|---|------|------------------|
| C1 | 위치 권한 사전 안내(rationale) → OS 프롬프트 | ✅ onboarding `_LocationPermissionPage` (onboarding_screen.dart:820) |
| C2 | 위치 동의 별도 체크박스 | ✅ `_agreeLocation` (auth_screen.dart:2244), 동의 timestamp secure storage |
| C3 | 포그라운드 한정 + 정확도 최소화 | ✅ 백그라운드/지오펜싱 없음, 대부분 LocationAccuracy.low |
| C4 | GPS 스푸핑 가드 | ✅ SecureLocation.guard 4개 경로 전부 |
| C5 | 서버 위치 좌표화/익명화 | ✅ ~100m 반올림 + isMapPublic off 시 null (app_state.dart:5522) ⚠️ recordMerchantInterest 원좌표 |
| C6 | **위치정보 수집·이용·제공 사실 확인자료 보관** (법 의무) | ❌ 없음 |
| C7 | **동의 철회 in-app (위치 동의 개별 off)** | ⚠️ 이메일 mailto만 (계정삭제 = all-or-nothing) |
| C8 | **제3자 제공 시 즉시 통보** (해당 시) | ❌ (현재 제3자 위치 제공 없음 → 해당 없을 가능성, 약관 명시 필요) |
| C9 | 계정 삭제 (Apple 의무) + 서버 PII 완전 삭제 | ⚠️ 로컬·users doc 삭제 OK, **letters 는 scrub만 (실삭제 X)** |
| C10 | 만 14세 미만 차단 | ⚠️ 자기신고 체크만, 생년월일 입력 없음 + KO 14 / EN 13 불일치 |
| C11 | **마케팅(광고성 정보) 별도 동의** (KR 정통망법) | ❌ consent_marketing_ts read만, write 없음 |
| C12 | 데이터 이동권(export) | ✅ settings_screen.dart:364 |

---

## D. 문제점 → 개선 방법 (우선순위)

### 🔴 출시 차단 (BLOCKER)
1. **위치기반서비스사업 신고** (B1) — emsit.go.kr 온라인 신고. 소상공인 간소화 신고 활용. *업무/법률 영역 — 코드 외.*
2. **위치기반서비스 이용약관 작성·게시** (B2/C대응) — 별도 문서 작성 후 docs/ + 앱 내 링크. 필수 기재사항(위 B2) 포함.
3. **privacy.html / terms.html 호스팅** (B3/B4) — thiscount.io 에 실제 배포 (현재 링크 404). → app_links.dart:9 URL 도달 확인.
4. **마케팅 동의 미수집** (C11) — 가입 동의 화면에 광고성 정보 수신(선택) 체크박스 추가 + `consent_marketing_ts` write. *코드 수정 가능.*
5. **서버 letters 실삭제** (C9) — 현재 scrub(상태 마킹)만, firestore.rules `delete: if false`. → Cloud Function(elevated)로 hard-delete, 또는 rules 조정. *백엔드 작업.*

### 🟡 출시 전 권장 (HIGH)
6. **연령 게이트 강화 + KO/EN 일관성** (C10) — 생년월일 입력 또는 명확한 14세 차단, 정책 문구 KR 14 / COPPA 13 통일.
7. **위치 동의 개별 철회 in-app** (C7) — 설정에 "위치 권한 끄기"(앱 설정 이동 + isMapPublic off) 동선, 단순 mailto 대체.
8. **위치 이용내역 로깅** (C6) — 위치 수집·이용 사실 확인자료 보관(법 의무). 최소한 동의/철회 시각은 이미 secure storage 에 있음 → 위치 사용 이벤트 로그 추가 검토.
9. **번역 시 본문 외부 전송 1회 고지** — MyMemory/Google Translate 로 letter 본문 전송됨(translation_service). 최초 번역 시 안내 필요.

### 🟢 정리 (LOW)
10. recordMerchantInterest 원좌표 → 100m 좌표화 통일 (app_state.dart:901).
11. iOS InfoPlist.strings 의 미사용 NSLocationAlwaysAndWhenInUseUsageDescription 14곳 제거.

---

## E. 코드로 즉시 처리 (Build 411 완료 ✅)
- ✅ C11 마케팅 동의 체크박스(선택) + `consent_marketing_ts` write (auth_screen.dart) + 14언어 i18n
- ✅ D6 연령 13/14 문구 통일 (privacy.html ko/en → 14세, EU 16세)
- ✅ D10 merchant interest 좌표 ~100m 좌표화 (app_state.dart:901)
- ✅ D11 미사용 iOS NSLocationAlways 문자열 14개 제거
- ✅ B2 위치기반서비스 이용약관 초안(ko/en) `docs/location_terms.html` 작성 + app_links 링크 + 설정 화면 노출 (⚠️ **법률 검토 + thiscount.io 호스팅 필요**)
- ✅ 보안 LOW: premium_screen admin-email brand 게이트 `!isProductionBuild` 가드

**여전히 코드 밖 (BLOCKER 잔존)**: B1 방통위 신고 / B3·B4·B2 thiscount.io 정적 호스팅 / C9 서버 letters hard-delete (Cloud Function) / App Store·Play 폼 제출.

## F. 코드 외 (업무/법률/배포)
- B1 방통위 신고, B3/B4 웹 호스팅, C9 Cloud Function hard-delete, App Store/Play 폼 제출.
