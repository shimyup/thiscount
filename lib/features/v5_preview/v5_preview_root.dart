import 'package:flutter/material.dart';
import 'theme/v5_tokens.dart';
import 'screens/v5_splash.dart';
import 'screens/v5_onboarding.dart';
import 'screens/v5_main_scaffold.dart';
import 'screens/v5_detail.dart';
import 'screens/v5_premium.dart';

/// v5 디자인 시스템 미리보기 루트.
/// `--dart-define=APP_INITIAL_ROUTE=/v5_preview` 또는 `Navigator.pushNamed('/v5_preview')`로 진입.
class V5PreviewRoot extends StatefulWidget {
  const V5PreviewRoot({super.key});

  @override
  State<V5PreviewRoot> createState() => _V5PreviewRootState();
}

class _V5PreviewRootState extends State<V5PreviewRoot> {
  String _stage = 'splash';
  int _mainTab = 0;

  void _go(String stage, {int? tab}) {
    setState(() {
      _stage = stage;
      if (tab != null) _mainTab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 부모 MaterialApp 위에 darken 오버레이로 v5 룩 강제
    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: V5Colors.bg,
        canvasColor: V5Colors.bg,
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: V5Colors.tx,
          displayColor: V5Colors.tx,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _buildStage(),
      ),
    );
  }

  Widget _buildStage() {
    switch (_stage) {
      case 'splash':
        return V5SplashScreen(
          key: const ValueKey('splash'),
          onContinue: () => _go('onboarding'),
          onDevJump: _go,
        );
      case 'onboarding':
        return V5OnboardingScreen(
          key: const ValueKey('onboarding'),
          onFinish: () => _go('main'),
          onDevJump: _go,
        );
      case 'detail':
        return V5DetailScreen(
          key: const ValueKey('detail'),
          onBack: () => _go('main', tab: _mainTab),
          onDevJump: _go,
        );
      case 'premium':
        return V5PremiumScreen(
          key: const ValueKey('premium'),
          onClose: () => _go('main', tab: 3),
          onDevJump: _go,
        );
      case 'main':
      default:
        return V5MainScaffold(
          key: ValueKey('main_$_mainTab'),
          initialIndex: _mainTab,
          onCardTap: () => _go('detail'),
          onPremiumTap: () => _go('premium'),
          onDevJump: _go,
        );
    }
  }
}
