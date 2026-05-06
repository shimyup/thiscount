import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';

/// v5 Wallet 디자인. 단일 페이지 + 자동 진행.
/// 기존 flow 유지: 4.2s 후 /home, skip 버튼.
class DeliveryIntroScreen extends StatefulWidget {
  const DeliveryIntroScreen({super.key});

  @override
  State<DeliveryIntroScreen> createState() => _DeliveryIntroScreenState();
}

class _DeliveryIntroScreenState extends State<DeliveryIntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _nextTimer;
  bool _moved = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _nextTimer = Timer(const Duration(milliseconds: 4200), _goHome);
  }

  void _goHome() {
    if (!mounted || _moved) return;
    _moved = true;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _nextTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langCode = context.select<AppState, String>(
      (s) => s.currentUser.languageCode,
    );
    final l = AppL10n.of(langCode);
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _goHome,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Text(
                      l.skip,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) {
                      // 카드 3장이 살짝 회전하며 stack
                      return SizedBox(
                        width: 240,
                        height: 280,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _miniCard(
                              category: AppColors.coupon,
                              ink: const Color(0xFF1A0008),
                              label: 'BLUE BOTTLE',
                              big: '1+1',
                              small: ' AMERICANO',
                              codeLeft: 'D-2',
                              codeRight: '7d',
                              rotate: -0.087,
                              translate: const Offset(-12, -28),
                              opacity:
                                  0.85 +
                                  0.15 * _controller.value.clamp(0, 1).toDouble(),
                            ),
                            _miniCard(
                              category: AppColors.premium,
                              ink: const Color(0xFF1A1300),
                              label: 'AIR MAIL · PREMIUM',
                              big: '@shimyup',
                              codeLeft: 'SEQ',
                              codeRight: '0421',
                              rotate: 0,
                              translate: const Offset(0, 0),
                              opacity: 1,
                            ),
                            _miniCard(
                              category: AppColors.coupon,
                              ink: const Color(0xFF1A0008),
                              label: 'CGV',
                              big: '30%',
                              small: ' OFF',
                              codeLeft: 'D-9',
                              codeRight: '14d',
                              rotate: 0.087,
                              translate: const Offset(12, 28),
                              opacity: 0.95,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l.deliveryIntroTitle,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 32,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(l.deliveryIntroSubtitle, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 28),
              _LoadingDots(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniCard({
    required Color category,
    required Color ink,
    required String label,
    String? big,
    String? small,
    String? bigText,
    required String codeLeft,
    required String codeRight,
    required double rotate,
    required Offset translate,
    required double opacity,
  }) {
    return Transform.translate(
      offset: translate,
      child: Transform.rotate(
        angle: rotate,
        child: Opacity(
          opacity: opacity.clamp(0, 1).toDouble(),
          child: Container(
            width: 220,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: category,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: ink.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.66,
                  ),
                ),
                const SizedBox(height: 12),
                if (bigText != null)
                  Text(
                    bigText,
                    style: TextStyle(
                      color: ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      letterSpacing: -0.4,
                    ),
                  )
                else
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: ink,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                        height: 1,
                      ),
                      children: [
                        TextSpan(text: big),
                        if (small != null)
                          TextSpan(
                            text: small,
                            style: TextStyle(
                              fontSize: 15,
                              color: ink.withValues(alpha: 0.55),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: ink, width: 1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        codeLeft,
                        style: TextStyle(
                          color: ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Text(
                        codeRight,
                        style: TextStyle(
                          color: ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          children: List.generate(3, (i) {
            final phase = (_controller.value + i / 3) % 1.0;
            final opacity = (0.2 + 0.8 * (1 - (phase - 0.5).abs() * 2)).clamp(
              0.2,
              1.0,
            );
            return Container(
              margin: const EdgeInsets.only(right: 6),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.premium.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
