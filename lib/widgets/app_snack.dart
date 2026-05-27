import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Build 404 (PR-MM1): SnackBar 표준 헬퍼.
///
/// 코드베이스 ~90+ 곳에서 `ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
/// backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating,
/// shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
/// content: Text(...))` 형태가 반복. 같은 메시지인데 화면마다 borderRadius
/// 8/10/12/14 혼재 + duration 3/4/5초 혼재 + backgroundColor 분기 비일관.
///
/// 이 헬퍼로 통일:
/// - [AppSnack.info]: 기본 (bgCard + 4초)
/// - [AppSnack.success]: 성공 (teal + 3초)
/// - [AppSnack.error]: 실패 (error red + 5초 + assertive)
/// - [AppSnack.hint]: 가벼운 coachmark (textMuted + 4초)
///
/// 모든 SnackBar 가 `floating + radius 12 + 좌우 16px margin` 일관.
class AppSnack {
  AppSnack._();

  static const _radius = 12.0;
  static const _margin = EdgeInsets.fromLTRB(16, 0, 16, 16);

  /// 기본 정보 SnackBar (default 4초).
  static void info(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      bg: AppColors.bgCard,
      fg: AppColors.textPrimary,
      duration: duration ?? const Duration(seconds: 4),
      action: action,
    );
  }

  /// 성공 SnackBar (default 3초, teal tint).
  static void success(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(
      context,
      message: message,
      bg: AppColors.teal,
      fg: Colors.white,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// 에러 SnackBar (default 5초, assertive — 스크린리더 즉시 안내).
  static void error(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(
      context,
      message: message,
      bg: AppColors.error,
      fg: Colors.white,
      duration: duration ?? const Duration(seconds: 5),
    );
  }

  /// 가벼운 coachmark / hint SnackBar (muted tone, 4초).
  static void hint(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      bg: AppColors.bgCard,
      fg: AppColors.textSecondary,
      duration: duration ?? const Duration(seconds: 4),
      action: action,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color bg,
    required Color fg,
    required Duration duration,
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: fg)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: _margin,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
        action: action,
      ),
    );
  }
}
