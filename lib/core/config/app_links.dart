/// 앱 내에서 사용하는 외부 링크 URL 모음
///
/// GitHub Pages 호스팅 방법:
///   1. GitHub에서 새 repo 생성 (예: lettergo-privacy)
///   2. 프로젝트의 docs/ 폴더를 해당 repo에 push
///   3. repo 설정 → Pages → Source: "Deploy from a branch" → Branch: main / docs
///   4. 아래 URL을 자신의 GitHub username으로 업데이트
///
/// 예시: https://shimyup.github.io/lettergo/privacy.html
abstract class AppLinks {
  // ── 개인정보 처리방침 ──────────────────────────────────────────────────────
  // ✅ GitHub Pages 배포 완료 — https://shimyup.github.io/lettergo/privacy.html
  static const String privacyPolicy =
      'https://shimyup.github.io/lettergo/privacy.html';

  /// 가입 나라에 맞는 개인정보 처리방침 URL 반환
  ///   대한민국 → ?lang=ko (한국어)
  ///   그 외 → ?lang=en (영어)
  static String privacyPolicyForCountry(String country) {
    final lang = country == '대한민국' ? 'ko' : 'en';
    return '$privacyPolicy?lang=$lang';
  }

  // ── 이용약관 (필요 시 추가) ────────────────────────────────────────────────
  // static const String termsOfService =
  //     'https://shimyup.github.io/lettergo/terms.html';

  // ── 고객 지원 ────────────────────────────────────────────────────────────
  static const String supportEmail = 'ceo@airony.xyz';
}
