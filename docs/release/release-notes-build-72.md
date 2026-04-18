# Release Notes — Build 72 (1.0.0+72)

Date: 2026-04-18

---

## Korean (한국어)

**핵심 변화: 실제로 다른 테스터들과 편지를 주고받게 되었습니다!**

- 이전 빌드까지는 보낸 편지가 서버에 업로드만 될 뿐, 다른 테스터가 보낸
  편지를 내려받는 로직이 없어서 inbox에 보이는 편지가 모두 로컬에서
  생성된 가짜 편지였습니다
- 이제 30초마다 서버에서 내 국가로 향하는 편지를 가져와 실제 수신이
  작동합니다

**지도에서 다른 온라인 회원 실시간 표시**

- 로그인한 다른 회원 타워가 30초마다 갱신되어 지도에 나타납니다
  (지도 공개 설정을 켠 회원만)
- 차단한 회원의 타워는 즉시 지도에서 사라집니다

**테스터에게는**

- 이제 서로 답장을 주고받을 수 있습니다
- 지도에서 "이 앱을 쓰는 다른 사람이 있다"는 생생한 감각을 느끼실 수 있습니다

---

## English

**Critical Fix: Testers can now actually exchange letters with each other**

- Prior builds only uploaded sent letters to the server — there was no
  code path that downloaded letters sent to the current user by other
  testers. All visible inbox letters were locally-generated mock data.
- This build adds a 30-second sync that fetches incoming letters from
  Firestore, making real cross-user letter exchange finally work.

**Live Other Users on the Map**

- Towers of other logged-in users (who opted into map visibility) now
  refresh every 30 seconds, giving the map a live social-presence feel.
- Blocking a sender removes their tower from the map immediately.

**What testers will notice**

- You can actually receive replies from other testers now
- The map shows real people, not only demo towers

---

## Japanese (日本語)

**重要な修正: テスター同士が実際に手紙をやり取りできるようになりました**

- 従来のビルドでは送信した手紙がサーバーにアップロードされるだけで、
  他のテスターから届いた手紙をダウンロードする仕組みが無く、inbox に
  表示されていたのは全てローカルで生成された偽の手紙でした
- 本ビルドから30秒ごとに自分の国宛の手紙をサーバーから取得するため、
  実際のクロスユーザー手紙交換が正しく動作します

**地図上の他オンラインユーザーをリアルタイム表示**

- ログイン中の他ユーザーのタワーが30秒ごとに更新されます
  （地図公開をオンにしているユーザーのみ）
- ブロックしたユーザーのタワーは地図から即座に消えます

---

## Chinese (中文)

**关键修复：测试者之间现在真的可以互相收发信件**

- 之前的版本只把发出的信件上传到服务器，没有从服务器下载"别的测试者
  发给我的信"的逻辑，导致 inbox 里所有信都是本地生成的假信
- 本构建新增了每 30 秒同步一次，从 Firestore 拉取目标国家为我所在
  国家的信件，真正的跨用户信件交换终于可以工作

**地图实时显示其他在线用户**

- 登录中的其他用户塔楼每 30 秒刷新一次（仅显示开启地图公开的用户）
- 屏蔽用户后，其塔楼从地图上立即消失

---

## Changes in this Build

### Code
- `lib/state/app_state.dart`:
  - New `startServerSync()` / `stopServerSync()` / `_runServerSync()`
    orchestration with `_syncInFlight` guard
  - `Timer.periodic(30s)` fires concurrently:
    - `_fetchIncomingLettersFromServer()`: queries `letters` where
      `destinationCountry == currentUser.country`, filters self /
      blocked / local-dup, places into `_inbox` (delivered) or
      `_worldLetters` (in-transit / near-you)
    - `fetchMapUsers(force: true)`: reuses existing infra but bypasses
      the 10-minute cache gate so other towers feel live
  - New `_letterFromFirestore()` helper to rebuild Letter objects from
    persisted doc shape
  - `setUser()` auto-starts sync; `dispose()` cancels the timer
  - `blockLetterSender()` now also immediately removes the blocked user
    from `_mapUsers` without waiting for the next sync tick

### Version
- `pubspec.yaml`: 1.0.0+71 → 1.0.0+72

### No changes
- UI layer (sync happens behind the scenes)
- Localization
- Build pipeline / scripts
- Beta flag gating

---

## Artifacts

- iOS IPA (signed, 37.9MB): `build/ios/ipa/Letter Go.ipa`
- Android AAB (53MB): `build/app/outputs/bundle/release/app-release.aab`
- Android APK (68MB): `build/app/outputs/flutter-apk/app-release.apk`

## Verification

- `flutter analyze`: 0 issues
- `flutter test`: All tests passed
- BETA_FREE_PREMIUM / BETA_ADMIN_EMAIL both injected and confirmed
  in both platform build logs

## 다음 점검 사항 (실기기 테스트 후 확인)

1. 테스터 A가 테스터 B에게 편지 발송 → 30초 이내 B의 inbox 에 나타나는지
2. B가 답장 → 30초 이내 A의 inbox 에 나타나는지
3. 지도에서 다른 테스터 타워가 보이는지
4. 차단 시 즉시 사라지는지
5. 네트워크 단절 시 에러 메시지 없이 조용히 대기하다가 복구되는지
6. 배터리 소모가 눈에 띄게 증가하지 않는지 (30초 폴링 → 약 1~2% /시간)
