import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import 'city_of_month.dart';

/// 이번 달 큐레이션 도시를 소개하는 카드.
/// 프로필·홈 화면에서 탭하면 해당 도시로 편지 쓰기 플로우로 진입 가능.
///
/// 디자인:
/// - 좌측 대형 이모지 (테마·도시 감성)
/// - 우측 헤드라인 + 설명
/// - 하단 부드러운 CTA 링크 ("이 도시로 편지 쓰기 →")
class CityOfMonthCard extends StatelessWidget {
  /// "이 도시로 편지 쓰기" 탭 시 실행할 콜백.
  /// nil 시 CTA 숨김 (정보 표시 전용).
  final VoidCallback? onWriteTap;

  /// 카드 외곽 마진 (Sliver 내부에서 직접 제어할 경우 빈 EdgeInsets).
  final EdgeInsetsGeometry? margin;

  const CityOfMonthCard({super.key, this.onWriteTap, this.margin});

  @override
  Widget build(BuildContext context) {
    final city = CityOfMonth.forThisMonth();
    final accent = Color(city.accentColor);
    final l10n = AppL10n.of(
      context.read<AppState>().currentUser.languageCode,
    );

    return Container(
      margin: margin ?? const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.18),
            AppColors.bgCard,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 상단: 월 배지 + 국가 플래그
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.cityOfMonthBadge(city.month),
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                city.countryFlag,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 4),
              Text(
                city.country,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── 중앙: 이모지 + 도시명 · 헤드라인
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                city.themeEmoji,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      city.cityName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      city.headline,
                      style: TextStyle(
                        color: accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            city.description,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          if (onWriteTap != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onWriteTap,
              child: Row(
                children: [
                  Text(
                    l10n.cityOfMonthCta,
                    style: TextStyle(
                      color: accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: accent,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
