import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../state/app_state.dart';
import '../theme/v5_tokens.dart';
import '../widgets/v5_dev_bar.dart';

class V5OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  final void Function(String) onDevJump;

  const V5OnboardingScreen({
    super.key,
    required this.onFinish,
    required this.onDevJump,
  });

  @override
  State<V5OnboardingScreen> createState() => _V5OnboardingScreenState();
}

class _V5OnboardingScreenState extends State<V5OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _total = 3;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _total - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    } else {
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V5Colors.bg,
      body: Column(
        children: [
          V5DevBar(current: 'onboarding', onJump: widget.onDevJump),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(_page + 1).toString().padLeft(2, '0')} — '
                          '${_total.toString().padLeft(2, '0')}',
                          style: V5Text.meta.copyWith(
                            color: V5Colors.tx3,
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onFinish,
                          child: Text(
                            _page < _total - 1
                                ? AppL10n.of(context
                                        .read<AppState>()
                                        .currentUser
                                        .languageCode)
                                    .v5OnboardingSkip
                                : '',
                            style: V5Text.meta.copyWith(
                              color: V5Colors.tx2,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: List.generate(_total, (i) {
                        final on = i <= _page;
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                              right: i < _total - 1 ? 4 : 0,
                            ),
                            height: 3,
                            decoration: BoxDecoration(
                              color: on ? V5Colors.tx : V5Colors.bg3,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: PageView(
                        controller: _ctrl,
                        onPageChanged: (i) => setState(() => _page = i),
                        children: const [
                          _Page1(),
                          _Page2(),
                          _Page3(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _next,
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: V5Colors.tx,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _page < _total - 1
                              ? AppL10n.of(context
                                      .read<AppState>()
                                      .currentUser
                                      .languageCode)
                                  .v5OnboardingNext
                              : AppL10n.of(context
                                      .read<AppState>()
                                      .currentUser
                                      .languageCode)
                                  .v5OnboardingStart,
                          style: V5Text.button.copyWith(color: V5Colors.bg),
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
}

class _Page1 extends StatelessWidget {
  const _Page1();

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Center(
            child: _CardSample(
              category: V5Category.coupon,
              brand: 'Blue Bottle 성수',
              big: '1+1',
              bigSmall: ' 아메리카노',
              desc: '서울 성동구 · 320m',
              codeLeft: 'D-2',
              codeRight: '7일 유효',
            ),
          ),
        ),
        Text(
          l.v5OnboardingPage1Title,
          style: V5Text.display.copyWith(fontSize: 32, letterSpacing: -1.4),
        ),
        const SizedBox(height: 10),
        Text(l.v5OnboardingPage1Sub, style: V5Text.body),
      ],
    );
  }
}

class _Page2 extends StatelessWidget {
  const _Page2();

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context.read<AppState>().currentUser.languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Center(
            child: SizedBox(
              width: 232,
              height: 270,
              child: Stack(
                children: [
                  // Build 267: V5Category.letter 일본 펜팔 카드 → 빵집 쿠폰 카드.
                  // 이전엔 신규 사용자가 첫 인상에 "메시지/펜팔 앱" 으로 오해했음.
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Transform.rotate(
                      angle: -0.087,
                      child: const _CardSample(
                        category: V5Category.coupon,
                        brand: 'Paris Baguette',
                        big: '20%',
                        bigSmall: ' 빵',
                        desc: '서울 강남구 · 410m',
                        codeLeft: 'D-3',
                        codeRight: '5일 유효',
                      ),
                    ),
                  ),
                  Positioned(
                    top: 36,
                    left: 28,
                    right: -28,
                    child: const _CardSample(
                      category: V5Category.coupon,
                      brand: 'CGV 강남',
                      big: '30%',
                      bigSmall: ' 영화',
                      desc: '주말 1관 한정',
                      codeLeft: 'D-9',
                      codeRight: '14일 유효',
                    ),
                  ),
                  Positioned(
                    top: 72,
                    left: 0,
                    right: 0,
                    child: Transform.rotate(
                      angle: 0.087,
                      child: const _CardSample(
                        category: V5Category.premium,
                        brand: 'Thiscount Premium',
                        big: '@shimyup',
                        desc: 'since 04 · 2026',
                        codeLeft: 'MEMBER',
                        codeRight: '#0421',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Text(
          l.v5OnboardingPage2Title,
          style: V5Text.display.copyWith(fontSize: 32, letterSpacing: -1.4),
        ),
        const SizedBox(height: 10),
        Text(l.v5OnboardingPage2Sub, style: V5Text.body),
      ],
    );
  }
}

class _Page3 extends StatelessWidget {
  const _Page3();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 96,
                      fontWeight: FontWeight.w800,
                      color: V5Colors.tx,
                      letterSpacing: -5.7,
                      height: 0.9,
                    ),
                    children: [
                      TextSpan(text: '5'),
                      TextSpan(
                        text: ' / ',
                        style: TextStyle(color: V5Colors.tx3),
                      ),
                      TextSpan(
                        text: '10',
                        style: TextStyle(color: V5Colors.tx3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _StampGrid(),
              ],
            ),
          ),
        ),
        Text(
          AppL10n.of(context.read<AppState>().currentUser.languageCode)
              .v5OnboardingPage3Title,
          style: V5Text.display.copyWith(fontSize: 32, letterSpacing: -1.4),
        ),
        const SizedBox(height: 10),
        Text(
          AppL10n.of(context.read<AppState>().currentUser.languageCode)
              .v5OnboardingPage3Sub,
          style: V5Text.body,
        ),
      ],
    );
  }
}

class _StampGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(10, (i) {
        final on = i < 5;
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: on ? V5Colors.premium : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: on ? V5Colors.premium : V5Colors.bg4,
              width: 1.5,
            ),
            boxShadow: on
                ? [
                    BoxShadow(
                      color: V5Colors.premium.withValues(alpha: 0.15),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class _CardSample extends StatelessWidget {
  final V5Category category;
  final String brand;
  final String? big;
  final String? bigSmall;
  // Build 267: bigText 폐기 — letter 카드 자리에 들어가던 인용 메시지 형식.
  // 이제 모든 카드가 coupon/premium 형식이라 RichText 분기만 사용.
  final String? desc;
  final String codeLeft;
  final String codeRight;

  const _CardSample({
    required this.category,
    required this.brand,
    this.big,
    this.bigSmall,
    this.desc,
    required this.codeLeft,
    required this.codeRight,
  });

  @override
  Widget build(BuildContext context) {
    final ink = category.ink;
    return Container(
      width: 232,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: category.bg,
        borderRadius: BorderRadius.circular(V5Radius.card),
        boxShadow: V5Shadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            brand.toUpperCase(),
            style: V5Text.brandLine.copyWith(
              color: ink.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: ink,
                  letterSpacing: -1.3,
                  height: 1,
                ),
                children: [
                  TextSpan(text: big),
                  if (bigSmall != null)
                    TextSpan(
                      text: bigSmall,
                      style: TextStyle(
                        fontSize: 16,
                        color: ink.withValues(alpha: 0.55),
                      ),
                    ),
                ],
              ),
            ),
          if (desc != null) ...[
            const SizedBox(height: 8),
            Text(
              desc!,
              style: V5Text.meta.copyWith(
                color: ink.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: ink, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  codeLeft,
                  style: V5Text.brandLine.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  codeRight,
                  style: V5Text.brandLine.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
