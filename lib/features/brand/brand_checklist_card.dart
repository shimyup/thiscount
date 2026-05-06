import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';

/// Build 156: 신규 Brand 유저 온보딩 체크리스트 카드.
/// 프로필 상단에 BrandAnalyticsCard 바로 위 배치. 모든 체크 완료 시 자동 숨김.
///
/// 체크 항목:
///   1️⃣ 사업자 인증 제출 (`isBrandVerified` → state.currentUser 의 verifiedAt)
///   2️⃣ 첫 편지 발송 (1 통 이상 sent)
///   3️⃣ 첫 픽업 도달 (fetchBrandAnalytics 결과 totalPicked >= 1)
///
/// 3/3 달성 시 카드 자체가 사라지고 BrandAnalyticsCard 만 남음.
class BrandChecklistCard extends StatefulWidget {
  final EdgeInsetsGeometry margin;
  const BrandChecklistCard({
    super.key,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  State<BrandChecklistCard> createState() => _BrandChecklistCardState();
}

class _BrandChecklistCardState extends State<BrandChecklistCard> {
  int _pickedSoFar = 0;
  bool _loadingPicks = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPickCount());
  }

  Future<void> _loadPickCount() async {
    final state = context.read<AppState>();
    final data = await state.fetchBrandAnalytics();
    if (!mounted) return;
    setState(() {
      _pickedSoFar = data?.totalPicked ?? 0;
      _loadingPicks = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        final l = AppL10n.of(state.currentUser.languageCode);
        final hasVerified = state.isBrandVerified;
        final hasSent = state.sent.isNotEmpty;
        final hasPicked = _pickedSoFar > 0;
        final doneCount =
            (hasVerified ? 1 : 0) + (hasSent ? 1 : 0) + (hasPicked ? 1 : 0);
        // 3/3 완료 or 픽업 데이터 로딩 중이면 안전하게 숨김.
        if (doneCount >= 3) return const SizedBox.shrink();
        if (_loadingPicks && !hasSent) {
          // 아직 발송 없으면 어차피 픽업 0 — 로딩 대기 없이 즉시 표시.
        }

        return Container(
          margin: widget.margin,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.coupon.withValues(alpha: 0.18),
                AppColors.coupon.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.coupon.withValues(alpha: 0.45),
              width: 1.3,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🚀', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.brandChecklistTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '$doneCount / 3',
                    style: const TextStyle(
                      color: AppColors.coupon,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _step(
                index: 1,
                done: hasVerified,
                title: l.brandChecklistStep1Title,
                body: l.brandChecklistStep1Body,
              ),
              const SizedBox(height: 6),
              _step(
                index: 2,
                done: hasSent,
                title: l.brandChecklistStep2Title,
                body: l.brandChecklistStep2Body,
              ),
              const SizedBox(height: 6),
              _step(
                index: 3,
                done: hasPicked,
                title: l.brandChecklistStep3Title,
                body: l.brandChecklistStep3Body,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _step({
    required int index,
    required bool done,
    required String title,
    required String body,
  }) {
    final color = done
        ? AppColors.coupon
        : AppColors.textMuted.withValues(alpha: 0.6);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? AppColors.coupon.withValues(alpha: 0.22)
                : AppColors.bgSurface,
            border: Border.all(color: color, width: 1.2),
          ),
          child: done
              ? const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: AppColors.coupon,
                )
              : Text(
                  '$index',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: done
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  decoration: done
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationColor: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                body,
                style: TextStyle(
                  color: AppColors.textMuted.withValues(
                    alpha: done ? 0.5 : 0.85,
                  ),
                  fontSize: 10.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
