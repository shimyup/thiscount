# Build 409 — 100-Sim Audit: 처리 결과 + 잔여 백로그

생성: 2026-05-30 / 100 시뮬레이션 → 143 confirmed (P0 4 / P1 48 / P2 83 / P3 8+35).

## 처리 완료 (Build 408 + 409)
- **P0 4건 전부 수정.**
- **P1 48건 중 42건 수정.** (Build 408: 29건 / Build 409: 13건 추가)
- 잔여 P1 6건은 아래 — 제품 결정 또는 디바이스 테스트 필요.

### Build 409 에서 추가 수정한 P1 (13건)
- P1.30 admin 부분 fetch 가 전체 목록 차단 → `_partialWarning` 분리 배너
- P1.31 UserManagement 후속 페이지 에러 시 page-1 폐기 + silent 500 cap → 부분 보존 + 경고
- P1.25 Brand 일일캡(200) 이 월간(10k)·구매 quota 무력화 → 일일캡을 월간 유효한도로 통일
- P1.27 cold-start reconcile 이 brand extra quota 를 낮은 서버값으로 덮어씀 → max 채택 + push-up
- P1.26 brand extra quota 서버 sync 실패 영구 미복구 → P1.27 push-up 으로 복구 경로 확보
- P1.22 express random blast 의 campaignId 가 쿠폰마다 달라 dedup 깨짐 → 공유 campaignId 주입
- P1.23 fetchBrandAnalytics 가 실패 시 0 대시보드 반환 → `queryWhereEqualsResult(ok)` 로 실패 시 null
- P1.37 partial-scrub 미재시도 → per-letter PATCH 최대 3회 재시도
- P1.36 scrub PII 미삭제 (부분) → read 경로 suppression(P0.3)으로 노출 차단 + 정직한 주석. *물리적 erasure 는 백로그(아래)*
- P1.24 BrandInsights 9 한국어 고정 문구 → `koEn` 현지화
- P1.16 brand 업그레이드 다이얼로그가 production 에서 '예약' 거짓 안내 → isProduction 분기 카피
- P1.32 admin Premium 부여가 대상에게 미전달 → `_restoreProfileFromServer` 에서 grant-only isPremium read-back
- P1.19 추천 명시 선호 카테고리 값공간 불일치 → `letter.category.key` 비교 (Build 408)

---

## 잔여 P1 (6건) — 제품 결정 / 디바이스 테스트 필요

### [security/billing] P1.17 + P1.33 — 티어 다운그레이드 권위 (⚠️ 위험, 신중 필요)
- `syncPremiumStatus` 의 `resolvedIsBrand = isBrand || _currentUser.isBrand` (app_state.dart) — 한 번 Brand 면 이 경로로 절대 강등 불가. 예약 다운그레이드(Brand→Free) 발효 시 isBrand 가 안 꺼짐.
- `_doSaveUserToFirestore` 가 isBrand 를 자주 write-back (위치 업데이트마다) → admin 강등을 기기가 되돌림. `_restoreProfileFromServer` 는 TRUE 방향만 복원.
- **왜 미수정**: OR-fallback 은 Build 405(NN1) 에서 신규 Brand 가입자가 RC entitlement 전파 전 cold-start 에서 강등되는 걸 막으려 의도적으로 넣은 것. 단순 제거 시 신규 Brand 가입 깨짐. 올바른 fix 는 "authoritative entitlement-loss sync" vs "cold-start preservation sync" 구분 리팩터 — RC↔AppState↔server 3방향 동기화 모델 결정 + 디바이스 결제 테스트 필요. 잘못하면 유료 고객의 Brand 가 벗겨지는 더 큰 회귀.
- **제안**: 예약 다운그레이드 발효 경로 전용 `demoteFromBrand()` 명시 메서드 추가 (OR-fallback 우회) + admin 강등은 서버 authoritative 플래그로. 별도 세션에서 결제 흐름 테스트와 함께.

### [i18n/billing] P1.14 + P1.20 — KRW 가격 하드코딩
- premium_screen.dart (₩4,900/₩99,000) + compose_screen.dart ExactDrop 티어 (₩6,000/10,000/40,000) 가 모든 로케일/스토어프론트에 고정 표시 + 실제 청구가와 불일치.
- **왜 미수정**: RevenueCat `StoreProduct.priceString` (현지화 가격) 으로 교체해야 하는데, 상품 로드 실패 시 fallback 처리 + 실제 스토어프론트 디바이스 테스트 필요. 표시 전용이라 출시 차단은 아니나 글로벌 출시 전 권장.
- **제안**: `PurchaseService.localizedPriceFor(productId)` getter 추가 (priceString ?? 하드코딩 fallback), 모든 가격 표시 사이트가 이를 사용.

### [bug] P1.15 — Premium 첨부 사진 미업로드 (수신자 placeholder)
- `_pickImage` 가 압축본을 로컬 경로에만 두고, 발송 시 그 로컬 경로가 imageUrl 로 저장됨 → 다른 기기 수신자는 placeholder.
- **왜 미수정**: voucher 흐름처럼 Firebase Storage 업로드 배선 + 실패 처리 + 디바이스 테스트 필요 (기능 작업). voucher 업로드 helper(`StorageService.letterImagePath`) 재사용 가능.

### [ux] P1.5 — 픽업 rollback UI 피드백 없음 (현재 무해)
- `pickupRolledBackLetterId` 를 읽는 UI 없음 → claim 패배 시 편지가 조용히 사라짐.
- **현재 무해**: Build 409 P1.3 fix 로 claim 은 maxReaders==1 letter 에만 발동하는데, 현재 모든 letter 는 maxReaders=3 (1인 전용 없음) → rollback 자체가 발생 안 함. 1인 전용 쿠폰 도입 시 main_scaffold 에 리스너 추가 필요.

---

## 백엔드 작업 필요 (앱만으로 불가)
- **GDPR Art.17 물리적 PII 삭제** (P1.36 잔여): firestore.rules `isAllowedLetterUpdate` 가 content/senderName/senderId 업데이트를 막아 client 에서 blank 불가. elevated 권한 Cloud Function 으로 실제 삭제 필요. 현재는 read-side suppression(P0.3)로 노출만 차단.
- **claimedLetters Firestore rule** (P1.28 잔여): 1인 전용 쿠폰 race 보호를 살리려면 claimedLetters 컬렉션 rule 추가 배포 필요.
- **release_preflight PRODUCTION_BUILD assert** (P1.29): 완료 — release_preflight.sh 에 production 빌드 시 PRODUCTION_BUILD=true 강제 추가.

---

## P2 (83건) / P3 (43건)
다음 라운드 백로그. 주요 P2 클러스터 (파일별):
- app_state.dart (17), world_map_screen.dart (13), app_localizations.dart (9, i18n 잔여), compose_screen.dart (8), main_scaffold.dart (6), premium_screen.dart (5), purchase_service.dart (4), inbox/stamp_album (3+3)
