import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';

/// Build 267: Brand 셀프서브 가입 폼.
///
/// 이전엔 admin_screen 깊은 곳에 묻혀 있어서 일반 사용자는 Brand 등급 신청
/// 경로 자체가 없었음. 이 위젯은 동일 폼을 일반 사용자도 settings/profile
/// 에서 직접 열 수 있도록 공용화.
///
/// 사용법:
/// ```dart
/// BrandVerificationSheet.show(context);
/// ```
///
/// 베타 기간 — `submitBrandVerification(autoApprove: true)` 라 즉시 ✅.
/// 정식 출시엔 admin 큐 기반 검토로 교체 필요 (`approveBrandVerification`).
class BrandVerificationSheet extends StatefulWidget {
  const BrandVerificationSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const BrandVerificationSheet(),
    );
  }

  @override
  State<BrandVerificationSheet> createState() =>
      _BrandVerificationSheetState();
}

class _BrandVerificationSheetState extends State<BrandVerificationSheet> {
  late final TextEditingController _numberCtrl;
  late final TextEditingController _docCtrl;
  late final TextEditingController _phoneCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _numberCtrl = TextEditingController(
      text: state.currentUser.businessRegistrationNumber ?? '',
    );
    _docCtrl = TextEditingController(
      text: state.currentUser.businessRegistrationDocUrl ?? '',
    );
    _phoneCtrl = TextEditingController(
      text: state.currentUser.businessContactPhone ?? '',
    );
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _docCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppL10n.of(state.currentUser.languageCode);
    final isVerified = state.isBrandVerified;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    color: isVerified ? AppColors.teal : AppColors.gold,
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
                isVerified
                    ? l.brandVerificationStatusApproved
                    : (state.currentUser.businessRegistrationNumber != null
                        ? l.brandVerificationStatusPending
                        : l.brandVerificationSubtitle),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              _field(
                label: l.brandVerificationNumberLabel,
                controller: _numberCtrl,
                hint: '123-45-67890',
                keyboard: TextInputType.number,
                enabled: !isVerified,
              ),
              const SizedBox(height: 10),
              _field(
                label: l.brandVerificationDocLabel,
                controller: _docCtrl,
                hint: 'https://.../cert.pdf',
                keyboard: TextInputType.url,
                enabled: !isVerified,
              ),
              const SizedBox(height: 10),
              _field(
                label: l.brandVerificationPhoneLabel,
                controller: _phoneCtrl,
                hint: '010-0000-0000',
                keyboard: TextInputType.phone,
                enabled: !isVerified,
              ),
              const SizedBox(height: 16),
              if (!isVerified)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting
                        ? null
                        : () async {
                            if (_numberCtrl.text.trim().isEmpty) return;
                            setState(() => _submitting = true);
                            try {
                              await state.submitBrandVerification(
                                businessRegistrationNumber: _numberCtrl.text,
                                businessRegistrationDocUrl: _docCtrl.text,
                                businessContactPhone: _phoneCtrl.text,
                                // 베타: 즉시 ✅. 정식엔 admin 큐 검토.
                                autoApprove: true,
                              );
                              if (!mounted) return;
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      l.brandVerificationSubmittedToast),
                                  backgroundColor: AppColors.teal,
                                ),
                              );
                            } finally {
                              if (mounted) setState(() => _submitting = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Text(
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
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboard,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboard,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            isDense: true,
            filled: true,
            fillColor: AppColors.bgSurface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
