# Release Notes — Build 75 (1.0.0+75)

Date: 2026-04-18

---

## Korean (한국어)

**서버 비용·성능 대폭 최적화**

- 서버 동기화 주기를 적응형·분리형으로 재설계했습니다
- 편지 수신: 로그인 직후 5분은 30초 주기 (체감 빠르게), 그 이후 90초
- 지도 타워 갱신: 180초 주기 (자주 안 바뀜)
- 백그라운드 진입 시 Firestore 호출 완전 정지 (배터리·비용 절감)
- 페이지 크기 50→20, 중복 검사 O(n)→O(1)

**예상 비용 감소**: Build 74 대비 **75~85%** (40K MAU 기준 월 $1,400 → $300)

**Firestore 배포 파일 포함**

- `firestore.rules`, `firestore.indexes.json`, `firebase.json`, `.firebaserc`
- 터미널에서 `firebase deploy --only firestore:rules` 로 배포 가능

---

## English

**Major Server Cost & Performance Optimization**

- Sync polling redesigned with adaptive, split cadence
- Incoming letters: 30s for the first 5 min, 90s thereafter
- Map towers: 180s (changes slowly)
- Full pause on app backgrounding (battery + cost save)
- Page size 50→20, duplicate check O(n)→O(1)

**Projected cost reduction**: ~75-85% vs Build 74
(40K MAU: $1,400/mo → $300/mo)

**Firestore deployment files included**

- `firestore.rules`, `firestore.indexes.json`, `firebase.json`,
  `.firebaserc`
- Deploy from terminal via `firebase deploy --only firestore:rules`

---

## Japanese (日本語)

**サーバーコスト・パフォーマンス最適化**

- 同期ポーリングを適応型・分離型に再設計
- 手紙受信: ログイン直後5分は30秒、以降90秒
- 地図タワー: 180秒
- バックグラウンド移行時にFirestore呼び出し完全停止
- ページサイズ 50→20、重複チェック O(n)→O(1)

**予想コスト削減**: Build 74 比 **75-85%**

---

## Chinese (中文)

**服务器成本与性能大幅优化**

- 将同步轮询重构为自适应·分离式
- 接收信件: 登录后5分钟内30秒, 之后90秒
- 地图塔楼: 180秒
- 应用进入后台时完全停止 Firestore 调用
- 页面大小 50→20, 重复检查 O(n)→O(1)

**预计成本降低**: 相比 Build 74 **75-85%**

---

## Changes in this Build

### Code
- `lib/state/app_state.dart`:
  - Dual-timer sync: `_syncTimer` (letters) + `_mapSyncTimer` (users)
  - Adaptive letter interval: `_letterSyncFast` (30s) for first 5 min,
    `_letterSyncSlow` (90s) afterwards, with `_scheduleNextLetterSync()`
    re-scheduling when the mode boundary is crossed
  - Map sync at fixed `_mapSyncInterval` (180s)
  - Background lifecycle integration: `pauseServerSyncForBackground()`
    on paused/detached, `resumeServerSyncFromBackground()` on resumed,
    hooked into existing `didChangeAppLifecycleState` observer
  - `_seenLetterIds: Set<String>` session cache — replaces three O(n)
    `List.any` duplicate scans with a single O(1) lookup. Populated on
    `loadFromPrefs()` from inbox/worldLetters/sent
  - Incoming letters page size reduced 50 → 20

### Deployment scaffolding (new files at repo root)
- `firestore.rules` — complete security rules with admin UID whitelist
  (placeholder `REPLACE_WITH_YOUR_UID_HERE`)
- `firestore.indexes.json` — composite indexes on letters
  (destinationCountry+sentAt, senderId+sentAt) for faster queries
- `firebase.json` — Firebase CLI deployment config
- `.firebaserc` — project ID `lettergo-147eb` binding

### Documentation
- `docs/release/server-cost-optimization.md` — full cost analysis +
  future FCM push roadmap + CLI deploy guide

### Version
- `pubspec.yaml`: 1.0.0+74 → 1.0.0+75

---

## Artifacts

- iOS IPA (signed, 37.9MB): `build/ios/ipa/Letter Go.ipa`
- Android AAB (53MB): `build/app/outputs/bundle/release/app-release.aab`
- Android APK (68MB): `build/app/outputs/flutter-apk/app-release.apk`

## Verification

- `flutter analyze`: 0 issues
- `flutter test`: All tests passed
- BETA flags injected in both platform build logs

## 배포 전 작업 (1회)

Firestore 보안 규칙을 배포해야 관리자 패널이 작동합니다.

1. `firebase login --reauth` (세션 갱신)
2. Firebase Console → Authentication → Users → ceo@airony.xyz 의 UID 복사
3. `sed -i '' "s/REPLACE_WITH_YOUR_UID_HERE/복사한UID/g" firestore.rules`
4. `firebase deploy --only firestore:rules,firestore:indexes`

상세 가이드: `docs/release/server-cost-optimization.md`,
`docs/release/firestore-rules-setup.md`
