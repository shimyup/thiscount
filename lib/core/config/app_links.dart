/// 앱 내에서 사용하는 외부 링크 URL 모음
///
/// Build 489 (출시 게이트): thiscount.io 가 아직 미서빙(HTTP 000)이라 인앱 약관
///   링크가 전부 깨져(404 → 심사 리젝) 있던 것을, **실제 운영 중인 GitHub Pages**
///   (`shimyup.github.io/thiscount-pages`, privacy/terms 200 확인)로 전환.
///   ⚠️ location_terms.html 은 pages 레포에 아직 미푸시(404) → 사용자가
///   `docs/location_terms.html` 을 thiscount-pages 레포에 push 해야 200.
///   추후 thiscount.io 도메인/호스팅 셋업 후 이 base 만 되돌리면 됨.
abstract class AppLinks {
  // ── 정적 문서 호스팅 base ──────────────────────────────────────────────────
  static const String _docsBase = 'https://shimyup.github.io/thiscount-pages';

  // ── 개인정보 처리방침 ──────────────────────────────────────────────────────
  static const String privacyPolicy = '$_docsBase/privacy.html';

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
  static const String termsOfService = '$_docsBase/terms.html';

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
  static const String locationTerms = '$_docsBase/location_terms.html';

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
