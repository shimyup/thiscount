# Release Notes — Build 57 (1.0.0+57)

Date: 2026-04-16

---

## Korean (한국어)

**보안 개선**

- Firebase 인증 정보가 더 이상 앱 코드에 하드코딩되지 않습니다 (환경 변수 필수)
- OTP 인증 시 타이밍 공격 방지를 위한 상수 시간 비교 적용
- 릴리스 빌드에서 개발용 OTP 코드가 노출되지 않도록 보호 처리

**버그 수정**

- SMS 오류 응답 처리 시 JSON 파싱 크래시 수정
- 전화번호 및 인증 방식이 SharedPreferences와 Firestore에 정상 저장되지 않던 문제 수정
- Android 인앱 결제 시 RevenueCat 키가 누락되던 문제 수정 (dart-define 빌드 적용)

**개선 사항**

- 설정 화면에서 SMS 인증 옵션 제거 (이메일 전용으로 통일)
- 국가별 전화번호 최소 자릿수 검증 강화 (한국 9자리, 미국 10자리 등)
- 작성 화면 및 알림 서비스 다국어 번역 보완

**서비스 정책**

- 국제 우편 서비스 제한 및 제재 준수를 위해 북한은 편지 발송 대상에서 제외되었습니다

---

## English

**Security Improvements**

- Firebase credentials are no longer hardcoded in app source (environment variables required)
- Constant-time comparison applied to OTP verification to prevent timing attacks
- Development OTP codes are now protected from exposure in release builds

**Bug Fixes**

- Fixed JSON parsing crash in SMS error response handling
- Fixed phone number and verification method not persisting to SharedPreferences and Firestore
- Fixed Android in-app purchases failing due to missing RevenueCat keys (dart-define build applied)

**Improvements**

- Removed SMS verification option from settings (unified to email-only)
- Strengthened phone number validation with country-specific minimum digits (Korea 9, US 10, etc.)
- Improved localization for compose screen and notification service

**Service Policy**

- North Korea has been excluded from letter destinations due to international postal service restrictions and sanctions compliance

---

## Japanese (日本語)

**セキュリティ改善**

- Firebase認証情報がアプリコードにハードコードされなくなりました（環境変数が必須）
- タイミング攻撃防止のため、OTP認証に定時間比較を適用
- リリースビルドで開発用OTPコードが露出しないよう保護処理

**バグ修正**

- SMSエラーレスポンス処理時のJSONパースクラッシュを修正
- 電話番号と認証方式がSharedPreferencesとFirestoreに正常保存されない問題を修正
- Android アプリ内課金でRevenueCatキーが欠落していた問題を修正（dart-defineビルド適用）

**改善事項**

- 設定画面からSMS認証オプションを削除（メール専用に統一）
- 国別の電話番号最小桁数バリデーションを強化（韓国9桁、米国10桁など）
- 作成画面と通知サービスの多言語翻訳を改善

**サービスポリシー**

- 国際郵便サービスの制限および制裁遵守のため、北朝鮮は手紙の送信先から除外されました

---

## Chinese (中文)

**安全改进**

- Firebase凭据不再硬编码在应用代码中（需要环境变量）
- OTP验证采用常量时间比较，防止计时攻击
- 发布版本中开发用OTP代码已做保护处理，不再暴露

**错误修复**

- 修复SMS错误响应处理中的JSON解析崩溃
- 修复手机号码和验证方式未正确保存到SharedPreferences和Firestore的问题
- 修复Android应用内购买因缺少RevenueCat密钥而失败的问题（已应用dart-define构建）

**改进**

- 从设置页面移除SMS验证选项（统一为仅邮箱验证）
- 加强国家/地区特定的手机号码最小位数验证（韩国9位、美国10位等）
- 改善编写页面和通知服务的多语言翻译

**服务政策**

- 由于国际邮政服务限制和制裁合规，朝鲜已从信件目的地中排除
