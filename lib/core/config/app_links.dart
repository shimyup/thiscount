/// 앱 내에서 사용하는 외부 링크 URL 모음
///
/// Build 221: 도메인 thiscount.io 등록 완료 (Namecheap, May 2026~).
/// privacy/terms 페이지는 thiscount.io 호스팅으로 이전 예정 — 우선 URL만 업데이트.
/// 페이지 미배포 시 출시 전 docs/privacy.html + docs/terms.html 을
/// thiscount.io 에 정적 호스팅 필수 (Vercel/Netlify/Cloudflare Pages).
abstract class AppLinks {
  // ── 개인정보 처리방침 ──────────────────────────────────────────────────────
  static const String privacyPolicy =
      'https://thiscount.io/privacy.html';

  /// 가입 나라에 맞는 개인정보 처리방침 URL 반환
  ///   대한민국 → ?lang=ko (한국어)
  ///   그 외 → ?lang=en (영어)
  static String privacyPolicyForCountry(String country) {
    final lang = country == '대한민국' ? 'ko' : 'en';
    return '$privacyPolicy?lang=$lang';
  }

  // ── 이용약관 ─────────────────────────────────────────────────────────────
  static const String termsOfService =
      'https://thiscount.io/terms.html';

  /// 가입 나라에 맞는 이용약관 URL 반환
  static String termsForCountry(String country) {
    final lang = country == '대한민국' ? 'ko' : 'en';
    return '$termsOfService?lang=$lang';
  }

  // ── 고객 지원 ────────────────────────────────────────────────────────────
  // 도메인 thiscount.io 의 메일 호스팅 설정 후 support@thiscount.io 로 전환.
  // 우선 기존 운영 메일 유지.
  static const String supportEmail = 'ceo@airony.xyz';

  /// Build 221: 앱 마케팅 / 랜딩 페이지
  static const String marketingSite = 'https://thiscount.io';
}
