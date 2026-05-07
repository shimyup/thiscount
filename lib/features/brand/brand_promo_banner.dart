import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/letter.dart';
import '../../state/app_state.dart';

/// Build 142: 앱 시작 시 지도 상단에 자동 슬라이드-다운 되는 브랜드 홍보
/// 배너 광고. 이전 `_BrandPromoTicket` 의 center modal 을 대체.
///
/// 동작:
///   - `initState` 직후 850ms 지연 후 표시 (지도 첫 렌더 뒤 부드럽게 등장)
///   - 8초 뒤 자동 접힘 (유저 탭 없을 때). 탭 하면 `onTap` 콜백 → 지도 이동
///   - 세션 내 1회만 — `state.promoShownThisSession` 플래그 + 앱 재시작 시 리셋
///   - Brand 본인은 숨김 (자기 캠페인이라 광고 대상 아님)
///   - 활성 브랜드 coupon/voucher 가 없으면 null 편지 → 렌더 안 함
///
/// 레이아웃:
///   - 가로 꽉 찬 노란 그라데이션 카드 (이전 티켓 톤 재사용)
///   - 좌측 🎟 이모지 / 가운데 "브랜드명 · 타이틀" / 우측 "자세히" CTA + ✕
class BrandPromoBanner extends StatefulWidget {
  final VoidCallback? onTapLetter; // 편지 상세 열기 콜백 (optional)
  final void Function(Letter letter)? onRevealOnMap; // 지도 좌표 이동 콜백

  const BrandPromoBanner({
    super.key,
    this.onTapLetter,
    this.onRevealOnMap,
  });

  @override
  State<BrandPromoBanner> createState() => _BrandPromoBannerState();
}

class _BrandPromoBannerState extends State<BrandPromoBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slide;
  Letter? _promo;
  bool _showing = false;
  bool _dismissed = false;
  // Build 143: 축소 상태 — 전체 배너에서 우상단 mini pill 로 전환.
  bool _minimized = false;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeShow();
    });
  }

  Future<void> _maybeShow() async {
    final state = context.read<AppState>();
    // Build 143: Brand 유저도 배너 노출. 자기 캠페인을 직접 확인하거나 다른
    // 브랜드 활동을 벤치마크할 수 있게. 이전엔 "자기 거라서 스팸" 논리였지만
    // 실제로는 "내 경쟁사가 뭘 뿌리는지" 가 Brand 에게도 유용.
    if (state.promoShownThisSession) return;
    final promo = state.featuredBrandPromo;
    if (promo == null) return;

    setState(() {
      _promo = promo;
      _showing = true;
      _minimized = false;
    });
    state.markPromoShownThisSession();

    await Future.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;
    _slideCtrl.forward();

    // Build 143: 3.2초 후 full 배너 → mini pill 로 축소 (완전히 사라지지 않고
    // 우상단 작은 🎟 칩으로 남아 있음). 유저 주의는 덜 끌면서 광고 도달률
    // 유지. 탭하면 다시 expand.
    await Future.delayed(const Duration(milliseconds: 3200));
    if (!mounted || _dismissed) return;
    setState(() => _minimized = true);
  }

  Future<void> _hide() async {
    if (!_showing) return;
    _dismissed = true;
    await _slideCtrl.reverse();
    if (!mounted) return;
    setState(() {
      _showing = false;
      _minimized = false;
    });
  }

  void _toggleExpand() {
    if (_dismissed) return;
    setState(() => _minimized = !_minimized);
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showing || _promo == null) return const SizedBox.shrink();
    final l10n = AppL10n.of(
      context.read<AppState>().currentUser.languageCode,
    );
    final promo = _promo!;
    final brandName = promo.senderName.isNotEmpty
        ? promo.senderName
        : l10n.brandTicketDefaultBrand;
    final title = _extractTitle(promo.content, l10n);

    return SlideTransition(
      position: _slide,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Align(
          alignment: Alignment.centerRight,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1.0).animate(anim),
                alignment: Alignment.topRight,
                child: child,
              ),
            ),
            child: _minimized
                ? _buildMiniPill(l10n)
                : _buildFullBanner(l10n, brandName, title, promo),
          ),
        ),
      ),
    );
  }

  /// 전체 배너 (등장 후 3.2초간 유지) — 🎟 + 브랜드명 · 홍보 태그 + 타이틀 + "자세히" CTA + ✕
  Widget _buildFullBanner(
    AppL10n l10n,
    String brandName,
    String title,
    Letter promo,
  ) {
    return Material(
      key: const ValueKey('full'),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          widget.onRevealOnMap?.call(promo);
          widget.onTapLetter?.call();
          _hide();
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.goldLight, AppColors.gold],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.32),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text('🎟', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            brandName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.goldDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.brandPromoBannerAdLabel,
                          style: TextStyle(
                            color: AppColors.goldDark
                                .withValues(alpha: 0.55),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.goldDark,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.goldDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.brandPromoBannerCTA,
                  style: const TextStyle(
                    color: AppColors.goldLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: _hide,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.goldDark.withValues(alpha: 0.7),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build 143: 축소 상태 mini pill — 우상단 🎟 한 개. 탭하면 다시 expand.
  /// 지도 시야 방해 최소화하면서 "광고 아직 있음" 만 표시.
  Widget _buildMiniPill(AppL10n l10n) {
    return Material(
      key: const ValueKey('mini'),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: _toggleExpand,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.goldLight, AppColors.gold],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎟', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Text(
                l10n.brandPromoBannerAdLabel.replaceAll('·', '').trim(),
                style: const TextStyle(
                  color: AppColors.goldDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _extractTitle(String content, AppL10n l) {
    final firstLine = content.split('\n').firstWhere(
          (s) => s.trim().isNotEmpty,
          orElse: () => '',
        );
    final trimmed = firstLine.trim();
    if (trimmed.isEmpty) return l.brandTicketFallbackTitle;
    // 그래핌(이모지/한글 결합) 단위로 자르기 — 코드유닛 기반 substring 은
    // 가족·피부톤 이모지나 결합형 한글에서 잘림 → mojibake 발생.
    if (trimmed.characters.length <= 28) return trimmed;
    return '${trimmed.characters.take(26)}…';
  }
}
