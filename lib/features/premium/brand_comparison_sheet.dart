import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Build 238: Premium 회원이 발송 진입 시 한 번 노출되는 Brand 비교 시트.
/// Premium 의 가치(사진+링크 홍보)에 만족하는 유저에게 Brand(광고주) 트랙의
/// 추가 권한(쿠폰/교환권 발행, 대량 발송, ExactDrop, 분석)을 환기시킨다.
/// 광고가 아니라 정보 — "준비됐을 때 옮겨갈 수 있다" 라는 안전감 강조.
class BrandComparisonSheet extends StatelessWidget {
  static bool _shownThisSession = false;

  const BrandComparisonSheet({super.key});

  static Future<void> showOncePerSession(BuildContext context) async {
    if (_shownThisSession) return;
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
  Widget build(BuildContext context) {
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
            const Text(
              '📣 Premium 발송 가이드',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '내 홍보 메시지를 세계에 뿌릴 수 있어요. 더 큰 광고가 필요하면 Brand 로 이동하세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
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
                    items: const [
                      '📸 사진 첨부',
                      '🔗 채널/SNS 링크',
                      '⚡ 빠른 배송',
                      '✉️ 일반 홍보 메시지',
                      '✅ 일반 카테고리 발송',
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
                    items: const [
                      '🎟 할인 쿠폰 발행',
                      '🎁 교환권 발행',
                      '📍 ExactDrop (정확 좌표)',
                      '📊 캠페인 분석',
                      '🌊 대량 발송',
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
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.textMuted, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Brand 는 광고주 트랙입니다. 사업자/브랜드 인증 후 쿠폰을 발행할 수 있어요.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '내 홍보 메시지 작성하기',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
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
  final List<String> items;

  const _TierColumn({
    required this.title,
    required this.badge,
    required this.color,
    required this.isCurrent,
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
                  child: const Text(
                    '내 등급',
                    style: TextStyle(
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
