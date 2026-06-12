import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';

/// Build 458 (페르소나 높음): 사업자 인증 제출 시트 — 이전엔 admin 화면에만
/// 있어 일반 Brand 사장은 체크리스트 1단계("사업자 인증 제출")에 도달할 방법이
/// 없었다. 프로필 체크리스트에서 직접 열 수 있는 공용 위젯으로 분리.
/// (admin_screen 의 기존 시트는 관리자용으로 유지.)
class BrandVerificationSheet {
  BrandVerificationSheet._();

  static Future<void> show(
    BuildContext context,
    AppState state,
    AppL10n l,
  ) async {
    final numberCtrl = TextEditingController(
      text: state.currentUser.businessRegistrationNumber ?? '',
    );
    final docCtrl = TextEditingController(
      text: state.currentUser.businessRegistrationDocUrl ?? '',
    );
    final phoneCtrl = TextEditingController(
      text: state.currentUser.businessContactPhone ?? '',
    );

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.brandVerificationTitle,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l.brandVerificationSubtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                _field(
                  label: l.brandVerificationNumberLabel,
                  controller: numberCtrl,
                  hint: '123-45-67890',
                  keyboard: TextInputType.number,
                ),
                const SizedBox(height: 10),
                _field(
                  label: l.brandVerificationDocLabel,
                  controller: docCtrl,
                  hint: 'https://.../cert.pdf',
                  keyboard: TextInputType.url,
                ),
                const SizedBox(height: 10),
                _field(
                  label: l.brandVerificationPhoneLabel,
                  controller: phoneCtrl,
                  hint: '010-0000-0000',
                  keyboard: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await state.submitBrandVerification(
                        businessRegistrationNumber: numberCtrl.text,
                        businessRegistrationDocUrl: docCtrl.text,
                        businessContactPhone: phoneCtrl.text,
                        // 베타: 입력 즉시 자동 승인 → ✅ 표시.
                        // 운영 시 관리자 검토 플로우로 교체 필요.
                        autoApprove: true,
                      );
                      if (!sheetCtx.mounted) return;
                      Navigator.pop(sheetCtx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l.brandVerificationSubmitCta,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      numberCtrl.dispose();
      docCtrl.dispose();
      phoneCtrl.dispose();
    });
  }

  static Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboard,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
            filled: true,
            fillColor: AppColors.bgSurface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
