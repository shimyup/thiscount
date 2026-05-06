import 'package:flutter/material.dart';
import '../theme/v5_tokens.dart';

class V5TowerScreen extends StatelessWidget {
  const V5TowerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V5Colors.bg,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _lvlTag(),
              const SizedBox(height: 12),
              Text('카운터.', style: V5Text.display.copyWith(fontSize: 32)),
              const SizedBox(height: 4),
              Text(
                '47통째 함께 — 04.13부터',
                style: V5Text.meta.copyWith(
                  color: V5Colors.tx2,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Center(child: _hero()),
              ),
              _stats(),
              const SizedBox(height: 12),
              _progress(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lvlTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: V5Colors.streak.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: V5Colors.streak,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'LEVEL 12',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: V5Colors.streak,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 280,
            height: 280,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x4DC77DFF), Colors.transparent],
              ),
            ),
          ),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: V5Colors.streak.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
          ),
          Container(
            width: 184,
            height: 184,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [V5Colors.streak, Color(0xFF5A2D9C)],
              ),
              boxShadow: [
                BoxShadow(
                  color: V5Colors.streak.withValues(alpha: 0.35),
                  blurRadius: 48,
                  offset: const Offset(0, 24),
                ),
              ],
            ),
            child: const Text(
              'L',
              style: TextStyle(
                color: Colors.white,
                fontSize: 96,
                fontWeight: FontWeight.w800,
                letterSpacing: -5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stats() {
    return Row(
      children: [
        Expanded(child: _statCell('47', '픽업', V5Colors.tx)),
        const SizedBox(width: 8),
        Expanded(child: _statCell('12', '발송', V5Colors.streak)),
        const SizedBox(width: 8),
        Expanded(child: _statCell('7d', '스트릭', V5Colors.tx)),
      ],
    );
  }

  Widget _statCell(String v, String k, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: V5Colors.bg2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            v,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.55,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            k,
            style: V5Text.meta.copyWith(
              color: V5Colors.tx2,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progress() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: V5Colors.bg2,
        borderRadius: BorderRadius.circular(V5Radius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '다음 단계까지',
                style: V5Text.meta.copyWith(
                  color: V5Colors.tx,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: V5Colors.tx2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  children: const [
                    TextSpan(
                      text: '65',
                      style: TextStyle(color: V5Colors.tx),
                    ),
                    TextSpan(text: ' / 100'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.65,
              minHeight: 6,
              backgroundColor: V5Colors.bg3,
              valueColor: AlwaysStoppedAnimation(V5Colors.streak),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '35통 더 모으면 모양이 바뀌어요',
            style: V5Text.meta.copyWith(
              color: V5Colors.tx2,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
