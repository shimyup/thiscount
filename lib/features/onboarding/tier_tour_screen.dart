import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import '../brand/brand_quick_send_wizard.dart';
import '../premium/premium_screen.dart';

/// Build 456: 로그인 후 1회 노출되는 **티어별 투어** (3장).
///
/// 가입 전 온보딩(OnboardingScreen)은 국가/위치/핵심가치 3장으로 축소하고,
/// 회원 종류를 알게 된 로그인 직후에 그 계정에 맞는 사용법만 보여준다:
///   - Brand: 캠페인 발송 → 매장 위치·자동 발송 → 할인코드·인사이트
///   - Premium: 1km 반경 줍기 → 특급·DM → 수집첩·코드 사용
///   - Free: 지도 줍기 → 수집첩·코드 사용 → Premium 소개(업셀, 선택)
///
/// 노출 조건: prefs `tier_tour_seen_v1 != true` (user-scoped — 계정 전환 시
/// _clearUserScopedPrefs 가 지워 새 계정도 자기 투어를 봄). 완료/건너뛰기 시
/// markSeen.
class TierTourScreen extends StatefulWidget {
  static const String seenPrefsKey = 'tier_tour_seen_v1';

  const TierTourScreen({super.key});

  /// MainScaffold 첫 진입 시 호출 — 안 봤으면 push.
  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(seenPrefsKey) == true) return;
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const TierTourScreen(),
      ),
    );
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(seenPrefsKey, true);
  }

  @override
  State<TierTourScreen> createState() => _TierTourScreenState();
}

class _TourSlide {
  final String emoji;
  final String title;
  final String body;
  final List<(String, String)> bullets; // (이모지, 텍스트)
  const _TourSlide({
    required this.emoji,
    required this.title,
    required this.body,
    this.bullets = const [],
  });
}

class _TierTourScreenState extends State<TierTourScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  List<_TourSlide> _slides(AppL10n l, bool isBrand, bool isPremium) {
    if (isBrand) {
      return [
        _TourSlide(
          emoji: '📣',
          title: l.koEn('동네 손님에게 쿠폰을 뿌리세요', 'Send coupons to nearby customers'),
          body: l.koEn(
            '캠페인 탭에서 일반홍보 · 할인권 · 교환권을 골라 발송하면 지도에 떨어지고, 근처 손님이 주워서 매장에 찾아와요.',
            'Pick Promo · Coupon · Voucher in the Campaign tab. It drops on the map, customers pick it up and visit your store.',
          ),
          bullets: [
            ('📨', l.koEn('일반홍보 — 소식·이벤트 알리기', 'Promo — news & events')),
            ('🎟', l.koEn('할인권 — 할인코드 자동 발급', 'Coupon — auto discount code')),
            ('🎁', l.koEn('교환권 — 이미지 첨부 교환', 'Voucher — image attached')),
          ],
        ),
        _TourSlide(
          emoji: '📍',
          title: l.koEn('매장 위치를 고정하세요', 'Lock your store location'),
          body: l.koEn(
            '발송 화면의 "매장 위치 · 자동 발송" 카드에서 위치를 한 번 고정하면, 근처에 온 손님에게 혜택이 자동으로 도착하게 할 수 있어요.',
            'Lock your location once in the "Store location · Auto-send" card — offers can then reach customers automatically when they come nearby.',
          ),
        ),
        _TourSlide(
          emoji: '🏷️',
          title: l.koEn('코드 한 번 등록, 성과는 인사이트에서', 'One code at POS, results in Insights'),
          body: l.koEn(
            '할인코드는 캠페인당 1개 — 매장 POS에 한 번만 등록하면 끝. 픽업·사용 성과는 인사이트 탭에서 실시간으로 확인하세요.',
            'One discount code per campaign — register it once at your POS. Track pickups & redemptions live in the Insights tab.',
          ),
        ),
      ];
    }
    if (isPremium) {
      return [
        _TourSlide(
          emoji: '🗺️',
          title: l.koEn('5배 넓게, 기다림 없이 주우세요', 'Pick up 5× wider, no waiting'),
          body: l.koEn(
            'Premium은 반경 1km 안의 혜택을 쿨다운 없이 연속으로 주울 수 있어요. 지도의 원이 내 줍기 범위예요.',
            'Premium picks up within a 1 km radius with no cooldown. The circle on the map is your range.',
          ),
        ),
        _TourSlide(
          emoji: '⚡',
          title: l.koEn('특급 발송과 1:1 채팅', 'Express send & 1:1 chat'),
          body: l.koEn(
            '내 편지를 5분 특급으로 보낼 수 있어요. 발송인과의 1:1 채팅(DM)은 베타 준비 중 — 정식 오픈 시 활성화돼요.',
            'Send your letters express (5 min). 1:1 chat (DM) is in beta preparation — it activates at full launch.',
          ),
        ),
        _TourSlide(
          emoji: '🎟',
          title: l.koEn('주운 쿠폰은 수집첩에', 'Picked coupons live in your collection'),
          body: l.koEn(
            '주운 할인권은 수집첩에 보관돼요. 매장에서 "사용 진행"을 누르면 코드가 크게 떠요. 같은 매장에서 쓸수록 단골 스탬프도 쌓여요!',
            'Coupons are kept in your collection. Tap "Redeem" at the store to reveal the code. Repeat visits earn loyalty stamps!',
          ),
        ),
      ];
    }
    return [
      _TourSlide(
        emoji: '🗺️',
        title: l.koEn('지도에서 혜택을 주우세요', 'Pick up offers on the map'),
        body: l.koEn(
          '주변 200m 안에 떨어진 할인권·교환권을 탭해서 주우세요. 지도의 원이 내 줍기 범위예요.',
          'Tap coupons & vouchers within 200 m to pick them up. The circle on the map is your range.',
        ),
      ),
      _TourSlide(
        emoji: '🎟',
        title: l.koEn('매장에서 바로 쓰세요', 'Use them right at the store'),
        body: l.koEn(
          '주운 쿠폰은 수집첩에 보관돼요. 매장에서 "사용 진행"을 누르면 코드가 크게 떠요. 같은 매장에서 쓸수록 단골 스탬프도 쌓여요!',
          'Picked coupons are kept in your collection. Tap "Redeem" at the store to reveal the code. Repeat visits earn loyalty stamps!',
        ),
      ),
      _TourSlide(
        emoji: '💎',
        title: l.koEn('더 넓게 줍고 싶다면 Premium', 'Want a wider range? Premium'),
        body: l.koEn(
          '반경 5배(1km) · 쿨다운 없음 · 특급 발송 · 1:1 채팅. 3일 무료로 시작할 수 있어요.',
          '5× radius (1 km) · no cooldown · express send · 1:1 chat. Start with a 3-day free trial.',
        ),
      ),
    ];
  }

  Future<void> _finish() async {
    await TierTourScreen.markSeen();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final l = AppL10n.of(state.currentUser.languageCode);
    final isBrand = state.currentUser.isBrand;
    final isPremium = state.currentUser.isPremium;
    final slides = _slides(l, isBrand, isPremium);
    final isLast = _page == slides.length - 1;
    final showPremiumCta = !isBrand && !isPremium && isLast;
    // Build 459: Brand 마지막 장 → '첫 캠페인 만들기' CTA (3스텝 마법사).
    final showBrandCta = isBrand && isLast;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            // 건너뛰기
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  l.skip,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final s = slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.emoji, style: const TextStyle(fontSize: 56)),
                        const SizedBox(height: 20),
                        Text(
                          s.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s.body,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14.5,
                            height: 1.55,
                          ),
                        ),
                        if (s.bullets.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          ...s.bullets.map(
                            (b) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Text(b.$1,
                                      style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      b.$2,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            // 인디케이터
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? (isBrand ? AppColors.coupon : AppColors.gold)
                        : AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  if (showBrandCta) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          await TierTourScreen.markSeen();
                          if (!mounted) return;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const BrandQuickSendWizard(),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.coupon,
                          foregroundColor: AppColors.bgDeep,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          l.koEn('📣 첫 캠페인 만들기', '📣 Create first campaign'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        l.koEn('나중에 할게요', 'Later'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ] else if (showPremiumCta) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          await TierTourScreen.markSeen();
                          if (!mounted) return;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const PremiumScreen(),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.bgDeep,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          l.koEn('💎 Premium 자세히 보기', '💎 See Premium'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (!showBrandCta)
                  SizedBox(
                    width: double.infinity,
                    child: showPremiumCta
                        ? TextButton(
                            onPressed: _finish,
                            child: Text(
                              l.koEn('무료로 시작하기', 'Start free'),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : FilledButton(
                            onPressed: () {
                              if (isLast) {
                                _finish();
                              } else {
                                _pageCtrl.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.bgDeep,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              isLast
                                  ? l.koEn('시작하기', 'Get started')
                                  : l.koEn('다음', 'Next'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
