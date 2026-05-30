# 회원정보(PII) 탈취 방지 — 공격 시뮬레이션 결과 (Build 412)

29 공격자 시나리오 → 16 confirmed (CRITICAL 1 / HIGH 2 / MED 12 / LOW 1). adversarial 검증 통과분.

## ✅ Build 412 에서 코드 수정 완료
- [HIGH] isUsernamePublic=false / isMapPublic=false do NOT remove username, country, countryFlag, or activity — `app_state.dart`
- [MED] Non-anonymous letters expose sender's precise (un-rounded) GPS origin tied to real identity — `app_state.dart`
- [MED] Brand verification PII (business registration number + contact phone + reg-doc URL) stored in plaint — `app_state.dart`
- [MED] iOS letter-decryption AES key stored with backup-restorable keychain accessibility (missing iOptions — `app_state.dart`
- [MED] Non-anonymous letter origin coordinates written to public `letters` collection at full GPS precision — `app_state.dart`
- [MED] trial_claims `get:true` is an unsalted-email membership oracle (rainbow-table enumeration of registe — `firestore.rules`
- [MED] Logout + cold-start bypasses isNewUser clear → next signup inherits prior user's Brand status, brand — `app_state.dart`
- [LOW] TTL clear relies on a Dart Timer that dies on app-kill — coupon code persists in clipboard indefinit — `secure_clipboard.dart`

## ⚠️ 코드 밖 / 아키텍처 (출시 전 반드시 처리)
- [CRITICAL] (backend) Live Resend (email) API key compiled into shipped IPA/APK — full mail-sending account takeover of the brand do
    fix: 1. IMMEDIATELY rotate/revoke the leaked key `re_MBwa…` in the Resend dashboard — treat it as fully compromised since it has shipped in prior TestFlight builds. Do the same for the Twilio token and SendGrid key if either was ever populated. 
- [HIGH] (backend) IDOR write on users/{userId}: anon auth has no owner binding, doc ids enumerable from public list → cross-user
    fix: PRIMARY (requires backend): Anonymous Firebase Auth cannot enforce per-doc ownership in rules, so move user-profile writes behind a server boundary. Add a Cloud Function (callable/HTTPS) or admin-REST proxy that authenticates the app's own 
- [MED] (backend) brand_zones redemptionCode stored plaintext + world-readable → mass coupon-code harvest
    fix: The real fix is backend, because (a) Firestore security rules cannot mask individual fields on read — read is all-or-nothing per document — and (b) anonymous Firebase Auth cannot owner-gate the brand_zones doc, so no rule can let in-zone us
- [MED] (backend) Entire /users collection is walkable by an unauthenticated attacker — reasonableListLimit() caps a single page
    fix: A per-page limit cannot stop pagination on a public-read collection, so this is not fully solvable in firestore.rules alone. Backend work required: (1) Stand up a Cloud Function (or server proxy) that paginates /users with a hard TOTAL cap,
- [MED] (backend) brand_zones redemptionCode (coupon value) world-readable by any anon user without entering the zone
    fix: Move redemptionCode out of the world-readable /brand_zones/{zoneId} document. The proposed client-side mask is insufficient because firestore.rules:296 `allow read: if true` lets any external party (even unauthenticated) GET the full doc vi
- [MED] (backend) Public, unmasked bulk read of users collection (client-side admin gate only) leaks invite codes, credit balanc
    fix: Effective enforcement requires backend work because the API key is embedded in the shipped binary and anonymous Firebase Auth (request.auth.uid is a per-session throwaway) makes a Firestore-rule owner check on /users impossible. Concrete pl
- [MED] (backend) adminFetchAllUsers performs unauthenticated, unmasked enumeration of the full users collection (client-side ad
    fix: Not client-fixable — an attacker bypasses the Flutter client entirely by replaying the REST list call with the bundled API key. The fix is backend (Firestore rules + server-side admin auth):

1. Close the open list/read rule on /users (fire
- [MED] (backend) Whitelisted credit fields (brandExactDropCredits / brandExtraMonthlyQuota / inviteRewardCredits) can be draine
    fix: See reasoning; see fix field.

## uncertain (추가 확인 권장)
- [MED] OTP / email / phone / temp-password auth screen has no screen-capture protection (release OTP code can be scre @ auth_screen.dart:2405
- [LOW] Private DM conversation content + partner names stored in plaintext SharedPreferences (letters are AES-encrypt @ app_state.dart:9434
- [LOW] Translate button leaks sender-authored letter body to MyMemory public Translation Memory with no in-UI notice  @ letter_read_screen.dart:238