import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Build 404 (PR-MM1): 표준 카드 컨테이너.
///
/// 코드베이스 전반에 `Container(decoration: BoxDecoration(...))` 가 ~120건
/// 분산. border radius (8/10/12/13/14/16/20 혼재) + alpha 값 (0.08/0.2/0.3/
/// 0.92 등) + border width (0.5/1/1.4) 가 화면마다 달라 시각 일관성 깨짐.
///
/// 이 위젯으로 통일:
/// - 기본 카드 (`AppCard()`): bgCard + radius 14 + 1px subtle border, shadow 없음
/// - 강조 카드 (`AppCard.accent(color: AppColors.gold)`): tinted border + 약한 background tint
/// - flat 카드 (`AppCard.flat()`): border 없는 단순 plate
///
/// callsite 가 색상/radius/alpha 를 직접 지정할 필요 없게 만들어 코드도
/// 읽기 쉬워진다.
class AppCard extends StatelessWidget {
  /// 표준 카드 padding (대부분 케이스 14).
  static const EdgeInsets defaultPadding = EdgeInsets.all(14);

  /// 표준 카드 corner radius (디자인 토큰 — 다른 화면도 이 값에 통일).
  static const double radius = 14;

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? accentColor;
  final bool flat;
  final bool emphasized;

  /// 기본 카드 — surface tone background + subtle hairline border.
  const AppCard({
    super.key,
    required this.child,
    this.padding = defaultPadding,
    this.onTap,
  })  : accentColor = null,
        flat = false,
        emphasized = false;

  /// 강조 카드 — accent color hint (tinted border + 8% bg tint).
  const AppCard.accent({
    super.key,
    required this.child,
    required Color color,
    this.padding = defaultPadding,
    this.onTap,
  })  : accentColor = color,
        flat = false,
        emphasized = false;

  /// flat 카드 — border 없는 단순 plate.
  const AppCard.flat({
    super.key,
    required this.child,
    this.padding = defaultPadding,
    this.onTap,
  })  : accentColor = null,
        flat = true,
        emphasized = false;

  /// 강조 active 카드 — accent border 더 진하게, 약한 elevation 효과.
  const AppCard.active({
    super.key,
    required this.child,
    required Color color,
    this.padding = defaultPadding,
    this.onTap,
  })  : accentColor = color,
        flat = false,
        emphasized = true;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor;
    final bgColor = accent == null
        ? AppColors.bgCard
        : Color.alphaBlend(
            accent.withValues(alpha: emphasized ? 0.12 : 0.08),
            AppColors.bgCard,
          );
    final borderColor = flat
        ? Colors.transparent
        : accent == null
            ? AppColors.bgSurface
            : accent.withValues(alpha: emphasized ? 0.5 : 0.3);
    final borderWidth = emphasized ? 1.4 : 1.0;
    final decoration = BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(radius),
      border: flat
          ? null
          : Border.all(color: borderColor, width: borderWidth),
    );
    final content = Padding(padding: padding, child: child);
    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: DecoratedBox(decoration: decoration, child: content),
      ),
    );
  }
}
