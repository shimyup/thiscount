import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/services/auth_service.dart';
import '../state/app_state.dart';

/// 닉네임 변경 불가 알림 스낵바
void showNicknameCooldownSnack(BuildContext ctx, AppState state) {
  final next = state.nextNicknameChangeAvailableAt;
  final dateLabel = next == null
      ? ''
      : ' (${next.year}.${next.month.toString().padLeft(2, '0')}.${next.day.toString().padLeft(2, '0')} 이후)';
  ScaffoldMessenger.of(ctx).showSnackBar(
    SnackBar(
      content: Text(
        '닉네임은 3개월에 1회만 변경할 수 있어요. 약 ${state.nicknameChangeRemainingDays}일 남았습니다$dateLabel',
      ),
      backgroundColor: AppColors.bgCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

/// 타워 이름 수정 다이얼로그
void showEditTowerNameDialog(BuildContext ctx, AppState state) {
  final ctrl = TextEditingController(
    text: state.currentUser.customTowerName ?? '',
  );
  showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        '타워 이름 설정',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: ctrl,
            maxLength: 20,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: '나만의 타워 이름 (최대 20자)',
              hintStyle: TextStyle(color: AppColors.textMuted),
              counterStyle: TextStyle(color: AppColors.textMuted),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.textMuted),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.teal),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '지도에서 타워 마커에 이름이 표시됩니다',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('취소', style: TextStyle(color: AppColors.textMuted)),
        ),
        TextButton(
          onPressed: () {
            state.updateTowerName(
              ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
            );
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('저장', style: TextStyle(color: AppColors.teal)),
        ),
      ],
    ),
  );
}

/// 닉네임 수정 다이얼로그
void showEditUsernameDialog(BuildContext ctx, AppState state) {
  final ctrl = TextEditingController(text: state.currentUser.username);
  showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        '닉네임 수정',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: TextField(
        controller: ctrl,
        maxLength: 20,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: '새 닉네임',
          hintStyle: TextStyle(color: AppColors.textMuted),
          counterStyle: TextStyle(color: AppColors.textMuted),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.textMuted),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.teal),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('취소', style: TextStyle(color: AppColors.textMuted)),
        ),
        TextButton(
          onPressed: () async {
            final name = ctrl.text.trim();
            if (name.length < 2) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('닉네임은 2자 이상이어야 합니다'),
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
          child: const Text('저장', style: TextStyle(color: AppColors.teal)),
        ),
      ],
    ),
  );
}
