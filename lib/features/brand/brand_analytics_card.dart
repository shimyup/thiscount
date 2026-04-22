import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';

/// Build 138: 브랜드 분석 대시보드 카드.
/// Brand 프로필에 배치되어 Firestore 집계 지표를 보여준다.
///   총 발송 · 총 픽업 · 총 사용 · 전환율
///   카테고리별(할인권/교환권) · 국가별 상위 5개
/// 네트워크 실패 시 친화적 에러 표시.
class BrandAnalyticsCard extends StatefulWidget {
  final EdgeInsetsGeometry margin;
  const BrandAnalyticsCard({
    super.key,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  State<BrandAnalyticsCard> createState() => _BrandAnalyticsCardState();
}

class _BrandAnalyticsCardState extends State<BrandAnalyticsCard> {
  BrandAnalytics? _data;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final state = context.read<AppState>();
    final data = await state.fetchBrandAnalytics();
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
      _error = data == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(
      context.read<AppState>().currentUser.languageCode,
    );
    return Container(
      margin: widget.margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF8A5C).withValues(alpha: 0.14),
            const Color(0xFFFF8A5C).withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF8A5C).withValues(alpha: 0.4),
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.brandAnalyticsTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                onPressed: _loading ? null : _load,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF8A5C),
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else if (_error || _data == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                l.brandAnalyticsOffline,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            )
          else
            _buildContent(l, _data!),
        ],
      ),
    );
  }

  Widget _buildContent(AppL10n l, BrandAnalytics d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3열 메인 지표
        Row(
          children: [
            Expanded(
              child: _statTile(
                label: l.brandAnalyticsSent,
                value: '${d.totalSent}',
                emoji: '📮',
              ),
            ),
            Expanded(
              child: _statTile(
                label: l.brandAnalyticsPicked,
                value: '${d.totalPicked}',
                emoji: '🎯',
              ),
            ),
            Expanded(
              child: _statTile(
                label: l.brandAnalyticsRedeemed,
                value: '${d.totalRedeemed}',
                emoji: '✅',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 전환율 + 리치율
        _rateRow(
          label: l.brandAnalyticsPickupReach,
          value: d.pickupReach,
          hint: '(picks / sent)',
        ),
        const SizedBox(height: 6),
        _rateRow(
          label: l.brandAnalyticsConversion,
          value: d.redeemConversion,
          hint: '(used / picks)',
        ),
        if (d.couponSent > 0 || d.voucherSent > 0) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              if (d.couponSent > 0) ...[
                _pill(emoji: '🎟', label: '${d.couponSent}'),
                const SizedBox(width: 8),
              ],
              if (d.voucherSent > 0) _pill(emoji: '🎁', label: '${d.voucherSent}'),
            ],
          ),
        ],
        if (d.countryPicks.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            l.brandAnalyticsTopCountries,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          ...(d.countryPicks.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .take(5)
              .map((e) => Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.key,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${e.value}',
                          style: const TextStyle(
                            color: Color(0xFFFF8A5C),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  )),
        ],
      ],
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required String emoji,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rateRow({
    required String label,
    required double value,
    required String hint,
  }) {
    final pct = (value * 100).toStringAsFixed(value > 0 && value < 0.01 ? 2 : 1);
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          hint,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
          ),
        ),
        const Spacer(),
        Text(
          '$pct%',
          style: const TextStyle(
            color: Color(0xFFFF8A5C),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _pill({required String emoji, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8A5C).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFF8A5C),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
