# Release Notes — Build 47 (1.0.0+47)

Date: 2026-04-11

---

## Korean (한국어)

**새로운 기능**

- 회원가입 시 핸드폰 번호가 필수 입력으로 변경되었습니다
- 국가코드 선택기가 추가되어 거주 국가에 맞는 번호가 자동 설정됩니다 (13개국)
- 전화번호는 국제 표준(E.164) 형식으로 자동 변환되어 저장됩니다

**개선 사항**

- 본인 인증은 이메일 OTP로 진행됩니다 (무료, 안정적)
- 전화번호는 형식 검증 후 계정에 저장되며, 향후 SMS 인증 활성화 대비 완료
- SMS 발송 인프라(Twilio)가 사전 구축되어 필요 시 즉시 활성화 가능

---

## English

**New Features**

- Phone number is now required at signup
- Country code picker added — automatically matches your residence country (13 countries)
- Phone numbers are stored in international E.164 format

**Improvements**

- Identity verification uses email OTP (free and reliable)
- Phone numbers are format-validated and saved to the account
- SMS infrastructure (Twilio) is pre-built for future activation when needed

---

## Japanese (日本語)

**新機能**

- 会員登録時に電話番号が必須になりました
- 国番号選択機能が追加され、居住国に合わせて自動設定されます（13カ国対応）
- 電話番号は国際標準（E.164）形式で保存されます

**改善点**

- 本人認証はメールOTPで行われます（無料・安定）
- 電話番号はフォーマット検証後、アカウントに保存されます
- SMS送信基盤（Twilio）は事前構築済み、必要時すぐに有効化可能

---

## Chinese (中文)

**新功能**

- 注册时手机号码改为必填项
- 新增国家代码选择器，自动匹配居住国家（支持13个国家）
- 手机号码以国际标准（E.164）格式存储

**改进**

- 身份验证通过邮箱OTP进行（免费且稳定）
- 手机号码经格式验证后保存至账户
- 短信发送基础设施（Twilio）已预先搭建，需要时可立即启用

---

## Technical Notes

- New file: `lib/core/services/sms_service.dart` — Twilio REST API SMS delivery (pre-built, inactive)
- Twilio credentials via dart-define: `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM_NUMBER`
- Phone number required at signup with country code picker (13 countries)
- Phone format validation + E.164 normalization via `SmsService.normalizePhoneNumber()`
- Verification uses email OTP only (cost: $0) — SMS toggle removed from UI
- SMS OTP methods (`generatePhoneOtp`, `verifyPhoneOtp`) preserved in AuthService for future use
- 14-language localization for all new UI strings
