/// 앱 내에서 사용하는 외부 링크 URL 모음
///
/// Build 221: 도메인 thiscount.io 등록 완료 (Namecheap, May 2026~).
/// privacy/terms 페이지는 thiscount.io 호스팅으로 이전 예정 — 우선 URL만 업데이트.
/// 페이지 미배포 시 출시 전 docs/privacy.html + docs/terms.html 을
/// thiscount.io 에 정적 호스팅 필수 (Vercel/Netlify/Cloudflare Pages).
abstract class AppLinks {
  // ── 개인정보 처리방침 ──────────────────────────────────────────────────────
  static const String privacyPolicy = 'https://thiscount.io/privacy.html';

  /// 가입 나라에 맞는 개인정보 처리방침 URL 반환
  ///   대한민국 → ?lang=ko (한국어)
  ///   그 외 → ?lang=en (영어)
  static String privacyPolicyForCountry(String country) {
    final lang = country == '대한민국' ? 'ko' : 'en';
    return '$privacyPolicy?lang=$lang';
  }

  /// Build 300 (MED audit): country 대신 langCode 우선 — '대한민국' 거주
  /// 비한국인 사용자가 영어 페이지를 봐야 하는 시나리오 대응.
  static String privacyPolicyForLanguage(String? langCode) {
    final lang = (langCode ?? '').toLowerCase().startsWith('ko') ? 'ko' : 'en';
    return '$privacyPolicy?lang=$lang';
  }

  // ── 이용약관 ─────────────────────────────────────────────────────────────
  static const String termsOfService = 'https://thiscount.io/terms.html';

  /// 가입 나라에 맞는 이용약관 URL 반환
  static String termsForCountry(String country) {
    final lang = country == '대한민국' ? 'ko' : 'en';
    return '$termsOfService?lang=$lang';
  }

  static String termsForLanguage(String? langCode) {
    final lang = (langCode ?? '').toLowerCase().startsWith('ko') ? 'ko' : 'en';
    return '$termsOfService?lang=$lang';
  }

  // ── 위치기반서비스 이용약관 (위치정보법 별도 약관 의무) ──────────────────
  // Build 411 (launch): 위치정보의 보호 및 이용 등에 관한 법률상 개인정보
  //   처리방침과 별개의 '위치기반서비스 이용약관' 게시 의무. docs/location_terms.html
  //   를 thiscount.io 에 호스팅 필요. 미게시 시 1천만원 이하 과태료.
  static const String locationTerms = 'https://thiscount.io/location_terms.html';

  static String locationTermsForLanguage(String? langCode) {
    final lang = (langCode ?? '').toLowerCase().startsWith('ko') ? 'ko' : 'en';
    return '$locationTerms?lang=$lang';
  }

  // ── 고객 지원 ────────────────────────────────────────────────────────────
  // Build 281: 사용자 노출 지원 채널.
  // Build 310: 1인 운영 단계라 ceo@airony.xyz 로 직접 수신 통일.
  // thiscount.io 메일 라우팅 셋업 후 다시 support@thiscount.io 로 전환 예정.
  static const String supportEmail = 'ceo@airony.xyz';

  /// Build 221: 앱 마케팅 / 랜딩 페이지
  static const String marketingSite = 'https://thiscount.io';
}
