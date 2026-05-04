import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';

/// Build 242: Cold-start 양방향 마켓 부트스트랩 — 빈 지도/수집첩에서 노출되는
/// 가맹점 영입 CTA. "사장님이세요?" 진입점이 admin_screen 깊은 곳에 숨어 있던
/// 문제 해소 — 일반 사용자 흐름에서 직접 가맹점 관심을 캡처.
///
/// 흐름:
///   1) 빈 상태에서 "주변에 가맹점이 없나요?" 카드 노출
///   2) 탭 → 이 시트 (혜택 3개 + 관심 등록 버튼)
///   3) 관심 등록 시: SharedPreferences (`merchant_interest_v1`) +
///      Firestore `merchant_interest` 컬렉션 전송 (도시 + 언어 + ts)
///   4) Closed beta 운영자가 이 리스트로 가맹점 영업 진행
class MerchantInterestSheet extends StatefulWidget {
  static const String _prefKeyRegistered = 'merchant_interest_registered_v1';

  const MerchantInterestSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const MerchantInterestSheet(),
    );
  }

  /// 이미 관심 등록한 사용자인지 확인 — 카드 숨김 조건 등에 사용
  static Future<bool> isAlreadyRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyRegistered) == true;
  }

  @override
  State<MerchantInterestSheet> createState() => _MerchantInterestSheetState();
}

class _MerchantInterestSheetState extends State<MerchantInterestSheet> {
  bool _submitting = false;
  bool _submitted = false;

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    HapticFeedback.mediumImpact();

    final state = context.read<AppState>();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(MerchantInterestSheet._prefKeyRegistered, true);
    await prefs.setString(
      'merchant_interest_at',
      DateTime.now().toIso8601String(),
    );
    await prefs.setString(
      'merchant_interest_city',
      state.currentUser.country,
    );

    // Firestore 전송은 best-effort — 네트워크 실패해도 로컬 저장은 유지
    try {
      await state.recordMerchantInterest(
        country: state.currentUser.country,
        countryFlag: state.currentUser.countryFlag,
        languageCode: state.currentUser.languageCode,
      );
    } catch (_) {
      // 무시 — 운영자가 SharedPreferences 표식으로도 추적 가능
    }

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<AppState>().currentUser.languageCode;
    final l10n = AppL10n.of(lang.isEmpty ? 'en' : lang);
    final orange = AppColors.coupon;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: orange.withValues(alpha: 0.45)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          if (!_submitted) ...[
            Text(
              l10n.merchantHookTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.merchantHookSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            _BenefitRow(
              emoji: '🎟',
              title: l10n.merchantBenefit1Title,
              body: l10n.merchantBenefit1Body,
            ),
            const SizedBox(height: 12),
            _BenefitRow(
              emoji: '📍',
              title: l10n.merchantBenefit2Title,
              body: l10n.merchantBenefit2Body,
            ),
            const SizedBox(height: 12),
            _BenefitRow(
              emoji: '📊',
              title: l10n.merchantBenefit3Title,
              body: l10n.merchantBenefit3Body,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: orange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: orange.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer, color: AppColors.coupon, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.merchantBetaOffer,
                      style: TextStyle(
                        color: orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.merchantInterestCta,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ] else ...[
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              l10n.merchantThanksTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.merchantThanksBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.merchantThanksClose,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;

  const _BenefitRow({
    required this.emoji,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
