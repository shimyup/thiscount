# Release Notes — Build 74 (1.0.0+74)

Date: 2026-04-18

---

## Korean (한국어)

**업데이트 / 재설치해도 데이터 보존**

- 앱을 업데이트하거나 재설치한 뒤에도 보낸 편지·타워 커스터마이징·활동 점수가
  자동으로 복원됩니다 (서버에서 복구)
- Android 는 Google Drive 백업을 활성화해서 OS 차원에서도 복원 가능
- 베타 Premium 은 정식 빌드 전환 시에만 초기화 (기존 Build 71 보안 가드 그대로)

**관리자 회원 관리 HTTP 403 에러 수정**

- 관리자 패널 → 회원 관리에서 회원 목록을 불러올 때 발생하던 HTTP 403
  오류를 수정했습니다

**테스터에게는**

- 기기를 바꾸거나 앱을 재설치해도 편지와 타워가 그대로 남아있어요
- 관리자 계정(ceo@airony.xyz)은 Firestore 규칙 게시 후 회원 관리 정상 작동

---

## English

**Data Preserved Across App Updates / Reinstalls**

- Sent letters, tower customization, and activity score now auto-restore
  after app updates or reinstalls (pulled from server on launch)
- Android enables Google Drive backup so OS-level restore also works
- Beta Premium is still wiped only on production-build cutover
  (Build 71 security guard unchanged)

**Admin Member Management HTTP 403 Fix**

- Fixed 403 error when loading the member list in the admin panel

**Testers**

- Letters and tower persist even when switching devices or reinstalling
- Admin account (ceo@airony.xyz) works once the Firestore rules are
  published (see docs/release/firestore-rules-setup.md)

---

## Japanese (日本語)

**アップデート／再インストール後もデータ保持**

- アプリの更新や再インストール後も、送信した手紙・タワーカスタマイズ・
  アクティビティスコアが自動復元されます（サーバーから復旧）
- Android は Google ドライブバックアップを有効化し OS レベルでも復元可能
- ベータ Premium は正式ビルド切替時のみクリア

**管理者画面 HTTP 403 エラー修正**

- 管理パネル → 会員管理でメンバー一覧を取得する際の 403 エラーを修正

---

## Chinese (中文)

**更新／重装后数据保留**

- 应用更新或重新安装后，发送的信件、塔楼自定义、活跃度分数会自动恢复
  （从服务器拉取）
- Android 启用了 Google Drive 备份，系统级恢复也可用
- 测试版 Premium 仍只在切换到正式构建时清除

**管理员会员管理 HTTP 403 错误修复**

- 修复了管理员面板 → 会员管理中获取成员列表时的 403 错误

---

## Changes in this Build

### Code
- `lib/state/app_state.dart`:
  - New `restoreFromServerIfMissing()` called right after `setUser()` —
    pulls `users/{myId}` profile + tower customization and `letters
    WHERE senderId == myId` back into local state if missing locally
  - Preserves local-over-server for edits (no overwrite), but accepts
    server activity-score if higher (prevents floor-counter regression)
  - `adminFetchAllUsers()` / `adminFetchAllLetters()` rewritten to use
    the API-key REST list endpoint (same as `fetchMapUsers`) instead
    of the Bearer-token path which Firestore rules were blocking (403)
  - Pagination support added (up to 500 users / 300 letters)

### Android backup
- `AndroidManifest.xml`: `android:allowBackup="true"` +
  `android:fullBackupContent` + `android:dataExtractionRules`
- `android/app/src/main/res/xml/backup_rules.xml`: include sharedpref,
  exclude `FlutterSecureStorage` (sensitive)
- `android/app/src/main/res/xml/data_extraction_rules.xml`: separate
  cloud-backup (no secure storage) vs device-transfer (with secure
  storage for direct device-to-device)

### Version
- `pubspec.yaml`: 1.0.0+73 → 1.0.0+74

---

## Artifacts

- iOS IPA (signed, 37.9MB): `build/ios/ipa/Letter Go.ipa`
- Android AAB (53MB): `build/app/outputs/bundle/release/app-release.aab`
- Android APK (68MB): `build/app/outputs/flutter-apk/app-release.apk`

## Verification

- `flutter analyze`: 0 issues
- `flutter test`: All tests passed
- BETA_FREE_PREMIUM / BETA_ADMIN_EMAIL both injected in both platform
  build logs

## ⚠️ 배포 전 필수 작업

### Firestore 보안 규칙 게시
관리자 403 수정이 작동하려면 Firestore 보안 규칙을 게시해야 합니다.

1. Firebase Console → lettergo-147eb → Authentication → Users 탭에서
   `ceo@airony.xyz` 의 User UID 복사
2. Firestore Database → 규칙 탭으로 이동
3. 세션 기록의 "관리자 UID 찾는 방법" 섹션 규칙을 붙여넣고 UID 교체
4. **게시** 클릭
5. 앱 재실행 → 회원 관리 메뉴에서 목록이 로드되는지 확인

### 서버 비용 관리
폴링 주기가 현재 30초라 MAU 증가 시 비용이 빠르게 올라갑니다.
- 소프트 런칭 (3K MAU): 월 $70~90
- 타겟 (40K MAU): 월 $1,000~1,700
- 10K MAU 도달 시 FCM 푸시로 전환 권장 (95% 절감)
