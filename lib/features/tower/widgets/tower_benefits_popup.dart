import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../state/app_state.dart';

/// Build 205: 레터(타워) 페이지 첫 진입 시 한 번 노출되는 혜택 안내 팝업.
///
/// 콘텐츠:
/// - 레벨업으로 무엇이 좋아지는지 (픽업 반경, 레벨 명칭 진화)
/// - 회원 등급별 혜택 매트릭스 (Free / Premium / Brand)
///
/// "다시 보지 않기" 체크박스를 켜면 SharedPreferences 에 영구 dismiss 플래그
/// 가 저장되어 이후 노출 안 됨. 켜지 않고 닫으면 다음 진입 시 또 나옴.
class TowerBenefitsPopup {
  static const String _prefKey = 'tower_benefits_popup_dismissed';

  /// dismissed 플래그가 없으면 1회 표시.
  static Future<void> showIfDue(BuildContext context) async {
    if (!context.mounted) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefKey) == true) return;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const _BenefitsDialog(),
    );
  }

  /// 다시보기 (메뉴에서 강제 호출용 — 현재 미연결, 추후 사용 가능).
  static void showForce(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const _BenefitsDialog(),
    );
  }
}

class _BenefitsDialog extends StatefulWidget {
  const _BenefitsDialog();

  @override
  State<_BenefitsDialog> createState() => _BenefitsDialogState();
}

class _BenefitsDialogState extends State<_BenefitsDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final user = state.currentUser;
    final isBrand = user.isBrand;
    final isPremium = user.isPremium;

    return Dialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 헤더 ─────────────────────────────────────────────────
              Row(
                children: [
                  const Text('📬', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      '내 레터 성장 가이드',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () => _close(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // ── 본문 (스크롤 가능) ───────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section(
                        title: '레벨업으로 얻는 것',
                        emoji: '🚀',
                        children: const [
                          _BulletRow(
                            emoji: '📍',
                            text: '픽업 반경 확장 — 레벨당 +10m',
                          ),
                          _BulletRow(
                            emoji: '🎖',
                            text: '명예 호칭 진화 — 견습→숙련→마을 우체장→…→전설의 편지꾼',
                          ),
                          _BulletRow(
                            emoji: '🐣',
                            text: '캐릭터/컴패니언/악세사리 해금',
                          ),
                          _BulletRow(
                            emoji: '✉️',
                            text: 'XP = 픽업×10 + 발송×5 + 거리 보너스',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _section(
                        title: '내 회원 등급 혜택',
                        emoji: '👑',
                        children: [
                          _TierBenefitRow(
                            label: 'Free',
                            color: AppColors.textSecondary,
                            highlight: !isPremium && !isBrand,
                            bullets: const [
                              '편지 줍기 200m 반경',
                              '60분 쿨다운',
                              '받은 편지 답장은 가능',
                            ],
                          ),
                          const SizedBox(height: 8),
                          _TierBenefitRow(
                            label: 'Premium',
                            color: AppColors.gold,
                            highlight: isPremium && !isBrand,
                            bullets: const [
                              '편지 줍기 1km 반경 + 10분 쿨다운',
                              '📸 사진 첨부 + 🔗 채널/SNS 링크 발송',
                              '일 30통 / 월 500통 발송',
                            ],
                          ),
                          const SizedBox(height: 8),
                          _TierBenefitRow(
                            label: 'Brand',
                            color: AppColors.coupon,
                            highlight: isBrand,
                            bullets: const [
                              '🎟 할인권 · 🎁 교환권 캠페인 발송',
                              '🎯 정확한 위치 지정 · 대량 발송',
                              '일 200통 / 월 10,000통 + ROI 분석',
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // ── 다시 보지 않기 + 닫기 ────────────────────────────────
              Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        setState(() => _dontShowAgain = !_dontShowAgain),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: _dontShowAgain
                                ? AppColors.gold
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _dontShowAgain
                                  ? AppColors.gold
                                  : AppColors.textMuted.withValues(alpha: 0.5),
                              width: 1.4,
                            ),
                          ),
                          child: _dontShowAgain
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: Color(0xFF1A1300),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '다시 보지 않기',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _close,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '확인',
                        style: TextStyle(
                          color: Color(0xFF1A1300),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _close() async {
    HapticFeedback.lightImpact();
    if (_dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(TowerBenefitsPopup._prefKey, true);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Widget _section({
    required String title,
    required String emoji,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  final String emoji;
  final String text;
  const _BulletRow({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Text(emoji, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TierBenefitRow extends StatelessWidget {
  final String label;
  final Color color;
  final bool highlight;
  final List<String> bullets;
  const _TierBenefitRow({
    required this.label,
    required this.color,
    required this.highlight,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: highlight ? color.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight
              ? color.withValues(alpha: 0.55)
              : AppColors.textMuted.withValues(alpha: 0.18),
          width: highlight ? 1.3 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF1A0008),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              if (highlight) ...[
                const SizedBox(width: 8),
                Text(
                  '내 등급',
                  style: TextStyle(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          for (final b in bullets)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '· $b',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
