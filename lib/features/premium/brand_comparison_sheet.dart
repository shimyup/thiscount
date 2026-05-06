import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';

/// Build 238: Premium 회원이 발송 진입 시 노출되는 Brand 비교 시트.
/// Premium 의 가치(사진+링크 홍보)에 만족하는 유저에게 Brand(광고주) 트랙의
/// 추가 권한(쿠폰/교환권 발행, 대량 발송, ExactDrop, 분석)을 환기시킨다.
/// 광고가 아니라 정보 — "준비됐을 때 옮겨갈 수 있다" 라는 안전감 강조.
///
/// Build 240:
///   • 14개 언어 i18n 적용 (이전엔 한국어 하드코딩)
///   • "다시 보지 않기" 체크박스 + SharedPreferences 영구 dismiss
///   • 세션당 1회 정책 유지 (영구 dismiss 시 영영 안 뜸)
class BrandComparisonSheet extends StatefulWidget {
  static const String _prefKeyDismissed = 'brand_comparison_dismissed_v1';
  static bool _shownThisSession = false;

  const BrandComparisonSheet({super.key});

  static Future<void> showOncePerSession(BuildContext context) async {
    if (_shownThisSession) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefKeyDismissed) == true) return;
    if (!context.mounted) return;
    _shownThisSession = true;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const BrandComparisonSheet(),
    );
  }

  @override
  State<BrandComparisonSheet> createState() => _BrandComparisonSheetState();
}

class _BrandComparisonSheetState extends State<BrandComparisonSheet> {
  bool _dontShowAgain = false;

  Future<void> _onClose() async {
    if (_dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(BrandComparisonSheet._prefKeyDismissed, true);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<AppState>().currentUser.languageCode;
    final l10n = AppL10n.of(lang.isEmpty ? 'en' : lang);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.brandCompTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.brandCompSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TierColumn(
                    title: 'PREMIUM',
                    badge: '👑',
                    color: AppColors.gold,
                    isCurrent: true,
                    currentBadgeLabel: l10n.brandCompCurrentBadge,
                    items: [
                      l10n.brandCompPremPhoto,
                      l10n.brandCompPremLink,
                      l10n.brandCompPremFast,
                      l10n.brandCompPremPromo,
                      l10n.brandCompPremGeneral,
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TierColumn(
                    title: 'BRAND',
                    badge: '🏢',
                    color: AppColors.coupon,
                    isCurrent: false,
                    currentBadgeLabel: l10n.brandCompCurrentBadge,
                    items: [
                      l10n.brandCompBrandCoupon,
                      l10n.brandCompBrandVoucher,
                      l10n.brandCompBrandExact,
                      l10n.brandCompBrandAnalytics,
                      l10n.brandCompBrandBulk,
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.brandCompFootnote,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Build 240: 다시 보지 않기 체크박스
            InkWell(
              onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: _dontShowAgain,
                        onChanged: (v) => setState(
                          () => _dontShowAgain = v ?? false,
                        ),
                        activeColor: AppColors.gold,
                        checkColor: Colors.black,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.brandCompDontShowAgain,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.brandCompCta,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierColumn extends StatelessWidget {
  final String title;
  final String badge;
  final Color color;
  final bool isCurrent;
  final String currentBadgeLabel;
  final List<String> items;

  const _TierColumn({
    required this.title,
    required this.badge,
    required this.color,
    required this.isCurrent,
    required this.currentBadgeLabel,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isCurrent ? 0.10 : 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: isCurrent ? 0.6 : 0.3),
          width: isCurrent ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(badge, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    currentBadgeLabel,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                text,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(
                    alpha: isCurrent ? 0.95 : 0.7,
                  ),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
