# App Store Submit Readiness — Build 282

TestFlight `1.0.0+282` (Delivery UUID `c37ae6e5-f93b-4d52-8526-b832d10d33c9`)
가 정식 launch 빌드 후보로 준비된 상태. 본 문서는 **Submit for Review 전
사용자가 직접 처리해야 하는 항목** 만 정리한다. 코드 / 인프라 측면 P0 는
PR #8 + #9 머지 후 모두 해소됨.

---

## ✅ 코드 / 인프라 측면 (자동 해소 완료)

| 영역 | 항목 | 상태 |
|---|---|---|
| Apple Review | Info.plist `NSLocationAlwaysAndWhenInUseUsageDescription` 제거 | ✅ Build 275 |
| Apple Privacy Manifest 2024 | `NSPrivacyCollectedDataTypePhoneNumber` 선언 | ✅ Build 275 |
| GDPR / KISA | 14세 self-attestation + `consent_age_above14_ts` audit log | ✅ Build 276 |
| GDPR / KISA | 14세 동의 14언어 번역 | ✅ Build 277 |
| GDPR Art.17 | hard-delete admin 스크립트 (`scripts/gdpr_hard_delete.py`) | ✅ Build 281 |
| CCPA | privacy.html 한·영 8-1 권리 + 8-2 침해 72시간 통지 | ✅ Build 275 |
| Privacy | EXIF GPS strip (compose + profile pickImage) | ✅ Build 281 |
| Brand 약속 | ExactDrop 100m 반경 enforcement (picker + 발송 2단계) | ✅ Build 281 |
| 보안 | `_launchSnsLink` http(s) 화이트리스트 (stored XSS 방어) | ✅ Build 276 |
| 매출 보호 | `BETA_UPGRADE_SIMULATOR` default false + release_preflight strict | ✅ Build 275 |
| QA | flutter analyze No issues / flutter test 48/48 pass | ✅ |
| TestFlight | Build 282 VALID + Internal Beta Group 추가 | ✅ |

## ⚠️ 사용자 직접 처리 항목 (Submit 전 필수)

### 1) thiscount.io 도메인 DNS — 옵션 A or B

**옵션 A (권장)**: Namecheap 에서 thiscount.io DNS 설정 (`docs/release/hosting-thiscount-io.md` 가이드).
- 설정 후 `curl -sI https://thiscount.io/privacy.html` 가 200 OK
- App Store Connect 의 Privacy/Support/Marketing URL 을 `thiscount.io` 도메인으로 입력

**옵션 B (즉시 가능)**: fallback URL 그대로 launch.
- `https://shimyup.github.io/thiscount/privacy.html` ✅ 200 OK 확인됨
- App Store Connect 의 Privacy/Support/Marketing URL 을 fallback URL 로 입력
- launch 후 도메인 설정되면 URL 만 update (재심사 불필요)

→ **권장: 옵션 B 로 즉시 launch + 후속 도메인 설정**.

### 2) In-App Purchases 4종 ASC 등록 + 가격 / 현지화 / 심사

App Store Connect → Thiscount → Features → In-App Purchases 에서:

| Product ID | Type | 권장 가격 (KRW) | 권장 가격 (USD) |
|---|---|---|---|
| `thiscount_premium_monthly_ios` | Auto-renewing subscription | ₩4,900 | $3.99 |
| `thiscount_brand_monthly_ios` | Auto-renewing subscription | ₩49,000 | $39.99 |
| `thiscount_gift_1month_ios` | Non-consumable | ₩4,900 | $3.99 |
| `thiscount_brand_extra_1000_ios` | Consumable | ₩9,900 | $9.99 |

각 IAP 에:
- Display name (ko/en)
- Description (ko/en)
- Screenshot (1242x2208 이상, IAP 가 표시되는 구매 시트 화면)
- Subscription duration / family (Premium / Brand monthly 모두 1 month)
- Review screenshot + Review notes

가이드: `docs/release/iap_submission/ios/` 폴더 참고.

### 3) 스크린샷 6장 캡처

- 6.7" iPhone (1290 x 2796) **최소 3장, 권장 6장**
- 캡처할 화면:
  1. 온보딩 첫 화면 (Thiscount 브랜드)
  2. 지도에 핀이 떠 있는 메인 화면
  3. 인박스 (쿠폰/혜택 카드 색상 구분)
  4. 쿠폰 상세 화면 (QR + 코드)
  5. 구독 (Premium) 화면
  6. Brand 프로필 (선택 — Brand 사용자에게만 의미 있음)

캡처 도구:
- Xcode 시뮬레이터에서 `Cmd+S` (저장됨: `~/Desktop/Simulator Screen Shot - …`)
- 또는 본 프로젝트의 `scripts/capture_ios_route_set.sh` 사용
- 또는 `scripts/capture_ios_store_screenshot.sh`

### 4) App Privacy Questionnaire (Apple)

ASC → App Privacy → 데이터 유형별 응답. `ios/Runner/PrivacyInfo.xcprivacy`
와 정합해야 함 (282 에서 PhoneNumber 추가됨):

| Data Type | Collected | Linked | Tracking | Purpose |
|---|---|---|---|---|
| Name | ✓ | ✓ | ✗ | App Functionality |
| Email Address | ✓ | ✓ | ✗ | App Functionality |
| **Phone Number** | ✓ | ✓ | ✗ | App Functionality |
| User ID | ✓ | ✓ | ✗ | App Functionality |
| Precise Location | ✓ | ✓ | ✗ | App Functionality |
| Photos or Videos | ✓ | ✓ | ✗ | App Functionality |
| Other User Content | ✓ | ✓ | ✗ | App Functionality |
| Purchase History | ✓ | ✓ | ✗ | App Functionality |
| Device ID | ✓ | ✓ | ✗ | App Functionality |

추적/광고 사용 X. 모두 App Functionality 목적만.

### 5) Age Rating

- **14세 미만 가입 차단** self-attestation 추가됐으므로 **17+ 또는 12+** 적절
- Apple 의 Age Rating questionnaire 에 정직하게 응답
- 사용자 생성 콘텐츠 (UGC, letter 본문) 있음 → 신고 / 차단 / 모더레이션 기능
  검토자에게 어필 (`reports` collection + admin 패널)

### 6) App Review Notes

`docs/release/app-store-review-notes.md` 의 내용을 그대로 paste (이미 Build
281 기준 완성됨, 282 와 동일).

특히 추가 코멘트:
> Build 282 includes age 14+ self-attestation (KISA + GDPR Art.8), CCPA opt-out
> rights, Privacy Manifest declarations including PhoneNumber, EXIF GPS
> stripping on profile / letter photos, and stored XSS protection on user
> social links.

### 7) Beta App Description (TestFlight 빌드 추가 시)

이미 282 가 Internal group 에 활성. **External Testing** (Apple TestFlight
사전 심사 통과 후 외부 베타) 으로 확장하려면:
- ASC → TestFlight → External Testing → 새 그룹 → 282 add
- 외부 베타 등록 시 first build 만 Apple 심사 (~24h)

## 권장 launch 순서

1. **(B) 실기기 회귀**: `docs/release/qa-checklist-build-282.md` 5분 안에 통과
2. **(3) 스크린샷 6장** 캡처 (시뮬레이터 또는 실기기)
3. **(2) IAP 4종** ASC 등록 + 가격 설정 (web UI 30-60분)
4. **(4) App Privacy questionnaire** 응답
5. **(5) Age Rating** 응답
6. **(6) Review Notes** 입력
7. **(1B) fallback URL** 입력 (Privacy/Support/Marketing)
8. **Submit for Review** → Apple 24-48h 심사
9. 심사 통과 후 release: manual or automatic
10. launch 후 thiscount.io DNS 설정 → URL update (재심사 X)

## 미해결 / 후속 sprint

- **278-281 expire 처리**: 본 commit 의 코드 baseline 이 들어있는지 불명. 282
  가 최신이라 자동 우선이지만, 깔끔하게 정리하려면 ASC web UI 에서 278/279/280/281
  각각 expire (각 30초) 또는 ASC API batch (명시 승인 필요).
- **GDPR hard-delete Cloud Functions**: 현재 Python 스크립트 (cron 의존). 다음
  sprint 에서 Firebase Functions `onSchedule("every 24 hours")` 로 마이그레이션
  (별도 task spawn 됨).
- **paste-ready 문서 282 갱신**: `app-store-connect-paste-ready.md` 가 Build 273
  기준. 다음 sprint 에 282 변경 반영 (현재 본문 변경은 작아서 launch 에 영향
  없음).
