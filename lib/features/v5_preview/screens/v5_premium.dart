import 'package:flutter/material.dart';
import '../theme/v5_tokens.dart';
import '../widgets/v5_dev_bar.dart';

class V5PremiumScreen extends StatelessWidget {
  final VoidCallback onClose;
  final void Function(String) onDevJump;

  const V5PremiumScreen({
    super.key,
    required this.onClose,
    required this.onDevJump,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V5Colors.bg,
      body: Column(
        children: [
          V5DevBar(current: 'premium', onJump: onDevJump),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: onClose,
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: V5Colors.bg3,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: V5Colors.tx,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _badge(),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                          height: 1.05,
                          color: V5Colors.tx,
                        ),
                        children: const [
                          TextSpan(text: '더 멀리,\n더 '),
                          TextSpan(
                            text: '자주.',
                            style: TextStyle(color: V5Colors.premium),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '픽업 무제한 · 모든 나라 발송 · 5분 특급',
                      style: V5Text.body.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 22),
                    _premiumCard(),
                    const SizedBox(height: 12),
                    _socialProof(),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: V5Colors.tx,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '3일 무료 시작',
                          style: V5Text.button.copyWith(color: V5Colors.bg),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        '언제든 해지 · 이후 ₩4,900/월 자동 결제',
                        style: V5Text.meta.copyWith(
                          color: V5Colors.tx3,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: V5Colors.premium.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: V5Colors.premium,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'UPGRADE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: V5Colors.premium,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumCard() {
    const ink = V5Colors.premiumInk;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: V5Colors.premium,
        borderRadius: BorderRadius.circular(V5Radius.card),
        boxShadow: V5Shadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AIR MAIL PASS',
            style: V5Text.brandLine.copyWith(
              color: ink.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                '₩4,900',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                  color: ink,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ 월',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ink.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: ink.withValues(alpha: 0.16), width: 1),
              ),
            ),
            child: Column(
              children: [
                _perk('모든 나라로 발송', '전 세계'),
                _perkDivider(ink),
                _perk('5분 특급 배송', '기본 24h'),
                _perkDivider(ink),
                _perk('위치 정확 지정', '±5m'),
                _perkDivider(ink),
                _perk('혜택 픽업 무제한', '기본 5/일'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _perkDivider(Color ink) =>
      Container(height: 1, color: ink.withValues(alpha: 0.10));

  Widget _perk(String label, String meta) {
    const ink = V5Colors.premiumInk;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: ink,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: V5Colors.premium,
              size: 12,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
          ),
          Text(
            meta,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ink.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialProof() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: V5Colors.bg2,
        borderRadius: BorderRadius.circular(V5Radius.tile),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: TextSpan(
              style: V5Text.meta.copyWith(
                color: V5Colors.tx2,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              children: const [
                TextSpan(
                  text: '4,200명',
                  style: TextStyle(
                    color: V5Colors.tx,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: '이 이미 사용 중'),
              ],
            ),
          ),
          Text(
            '★★★★☆ 4.8',
            style: V5Text.meta.copyWith(
              color: V5Colors.tx3,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
