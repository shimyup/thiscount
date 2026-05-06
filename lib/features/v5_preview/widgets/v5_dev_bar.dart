import 'package:flutter/material.dart';
import '../theme/v5_tokens.dart';

/// preview 모드 전용 — 화면 간 빠른 점프용 상단 바.
/// 실제 production 화면에서는 사용하지 않음.
class V5DevBar extends StatelessWidget implements PreferredSizeWidget {
  final String current;
  final void Function(String) onJump;

  const V5DevBar({super.key, required this.current, required this.onJump});

  static const _screens = [
    'splash',
    'onboarding',
    'main',
    'detail',
    'premium',
  ];

  @override
  Size get preferredSize => const Size.fromHeight(36);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: V5Colors.bg,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _screens.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final s = _screens[i];
          final on = s == current;
          return GestureDetector(
            onTap: () => onJump(s),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: on ? V5Colors.tx : V5Colors.bg3,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                s,
                style: TextStyle(
                  color: on ? V5Colors.bg : V5Colors.tx2,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.06,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
