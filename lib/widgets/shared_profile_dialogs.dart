import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';
import '../core/services/auth_service.dart';
import '../state/app_state.dart';

/// 닉네임 변경 불가 알림 스낵바
void showNicknameCooldownSnack(BuildContext ctx, AppState state) {
  final l = AppL10n.of(state.currentUser.languageCode);
  final langCode = state.currentUser.languageCode;
  final next = state.nextNicknameChangeAvailableAt;
  final dateLabel = next == null
      ? ''
      : ' (${DateFormat.yMd(langCode).format(next)})';
  ScaffoldMessenger.of(ctx).showSnackBar(
    SnackBar(
      content: Text(
        l.profileDialogNicknameCooldown(state.nicknameChangeRemainingDays, dateLabel),
      ),
      backgroundColor: AppColors.bgCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

/// 타워 이름 / 레터 이름 수정 다이얼로그 (Build 171).
/// 같은 `customTowerName` 필드를 공유하되 티어별 라벨 분기:
///   Brand        → "타워 이름"
///   Free/Premium → "레터 이름"
void showEditTowerNameDialog(BuildContext ctx, AppState state) {
  final l = AppL10n.of(state.currentUser.languageCode);
  final isBrand = state.currentUser.isBrand;
  final ctrl = TextEditingController(
    text: state.currentUser.customTowerName ?? '',
  );
  showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isBrand ? l.profileDialogTowerNameTitle : l.profileDialogLetterNameTitle,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: ctrl,
            maxLength: 20,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: isBrand
                  ? l.profileDialogTowerNameHint
                  : l.profileDialogLetterNameHint,
              hintStyle: const TextStyle(color: AppColors.textMuted),
              counterStyle: const TextStyle(color: AppColors.textMuted),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.textMuted),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.teal),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isBrand
                ? l.profileDialogTowerNameDesc
                : l.profileDialogLetterNameDesc,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.settingsCancel, style: const TextStyle(color: AppColors.textMuted)),
        ),
        TextButton(
          onPressed: () {
            state.updateTowerName(
              ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
            );
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: Text(l.settingsSave, style: const TextStyle(color: AppColors.teal)),
        ),
      ],
    ),
  );
}

/// 닉네임 수정 다이얼로그
void showEditUsernameDialog(BuildContext ctx, AppState state) {
  final l = AppL10n.of(state.currentUser.languageCode);
  final ctrl = TextEditingController(text: state.currentUser.username);
  showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        l.profileDialogEditNickname,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: TextField(
        controller: ctrl,
        maxLength: 20,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: l.profileDialogNewNickname,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          counterStyle: const TextStyle(color: AppColors.textMuted),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.textMuted),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.teal),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.settingsCancel, style: const TextStyle(color: AppColors.textMuted)),
        ),
        TextButton(
          onPressed: () async {
            final name = ctrl.text.trim();
            if (name.length < 2) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(l.profileDialogNicknameMin2),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }
            if (name == state.currentUser.username) {
              if (ctx.mounted) Navigator.pop(ctx);
              return;
            }
            if (!state.canChangeNicknameNow()) {
              showNicknameCooldownSnack(ctx, state);
              return;
            }
            await AuthService.updateProfile(username: name);
            if (!ctx.mounted) return;
            final changed = state.updateUsername(name);
            if (!changed) {
              showNicknameCooldownSnack(ctx, state);
              return;
            }
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: Text(l.settingsSave, style: const TextStyle(color: AppColors.teal)),
        ),
      ],
    ),
  );
}
