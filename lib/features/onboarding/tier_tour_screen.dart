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
          title: l.tierTourBrandTitle1,
          body: l.tierTourBrandBody1,
          bullets: [
            ('📨', l.tierTourBrandBullet1),
            ('🎟', l.tierTourBrandBullet2),
            ('🎁', l.tierTourBrandBullet3),
          ],
        ),
        _TourSlide(
          emoji: '📍',
          title: l.tierTourBrandTitle2,
          body: l.tierTourBrandBody2,
        ),
        _TourSlide(
          emoji: '🏷️',
          title: l.tierTourBrandTitle3,
          body: l.tierTourBrandBody3,
        ),
      ];
    }
    if (isPremium) {
      return [
        _TourSlide(
          emoji: '🗺️',
          title: l.tierTourPremiumTitle1,
          body: l.tierTourPremiumBody1,
        ),
        _TourSlide(
          emoji: '⚡',
          title: l.tierTourPremiumTitle2,
          body: l.tierTourPremiumBody2,
        ),
        _TourSlide(
          emoji: '🎟',
          title: l.tierTourPremiumTitle3,
          body: l.tierTourPremiumBody3,
        ),
      ];
    }
    return [
      _TourSlide(
        emoji: '🗺️',
        title: l.tierTourFreeTitle1,
        body: l.tierTourFreeBody1,
      ),
      _TourSlide(
        emoji: '🎟',
        title: l.tierTourFreeTitle2,
        body: l.tierTourFreeBody2,
      ),
      _TourSlide(
        emoji: '💎',
        title: l.tierTourFreeTitle3,
        body: l.tierTourFreeBody3,
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
                          l.tierTourBrandCta,
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
                        l.tierTourLater,
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
                          l.tierTourPremiumCta,
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
                              l.tierTourStartFree,
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
                              isLast ? l.tierTourGetStarted : l.next,
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
