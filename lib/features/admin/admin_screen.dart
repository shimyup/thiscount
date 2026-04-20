import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/config/app_keys.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/purchase_service.dart';
import '../../state/app_state.dart';
import '../../models/letter.dart';
import 'user_management_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // ── 배송 속도 슬라이더 ──────────────────────────────────────────────────────
  static const List<double> _speedOptions = [
    1,
    2,
    5,
    10,
    30,
    60,
    100,
    500,
    1000,
  ];
  AppL10n _l10n(BuildContext context) =>
      AppL10n.of(context.read<AppState>().currentUser.languageCode);

  String _speedLabelAt(AppL10n l, int index) {
    if (index == 0) {
      return l.koEn('×1 (기본)', '×1 (Default)');
    }
    return '×${_speedOptions[index].toInt()}';
  }

  int _speedIndex(double multiplier) {
    for (int i = 0; i < _speedOptions.length; i++) {
      if (_speedOptions[i] >= multiplier) return i;
    }
    return _speedOptions.length - 1;
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError
            ? AppColors.error
            : AppColors.teal.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmAction({
    required String title,
    required String content,
    required VoidCallback onConfirm,
    bool isDanger = false,
  }) {
    final l = _l10n(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(
            color: isDanger ? AppColors.error : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          content,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l.koEn('취소', 'Cancel'),
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(
              l.koEn('확인', 'Confirm'),
              style: TextStyle(
                color: isDanger ? AppColors.error : AppColors.teal,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = _l10n(context);
    final state = context.watch<AppState>();
    final purchase = context.watch<PurchaseService>();
    final colors = AppTimeColors.of(context);
    final curSpeedIdx = _speedIndex(state.adminSpeedMultiplier);
    final user = state.currentUser;
    // 관리자 접근 허용 조건:
    // 1) 디버그 빌드 + 하드코딩된 테스트 브랜드 이메일, 또는
    // 2) 베타 dart-define 으로 주입된 BETA_ADMIN_EMAIL 과 일치 (정식 빌드 차단용).
    final isAllowedAdmin =
        (kDebugMode &&
            user.email?.toLowerCase() == DebugConstants.testBrandEmail) ||
        BetaConstants.isAdmin(user.email);

    if (!isAllowedAdmin) {
      return Scaffold(
        backgroundColor: colors.bgDeep,
        appBar: AppBar(
          backgroundColor: colors.bgDeep,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            l.koEn('관리자 패널', 'Admin Panel'),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ),
        body: Center(
          child: Text(
            l.koEn('접근 권한이 없습니다.', 'Access denied.'),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.bgDeep,
      appBar: AppBar(
        backgroundColor: colors.bgDeep,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Text(
                l.labelAdmin,
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l.koEn('관리자 패널', 'Admin Panel'),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        children: [
          // ──────────────────────────────────────────────────────────────────
          // 👥 회원 관리
          // ──────────────────────────────────────────────────────────────────
          _sectionHeader(l.koEn('👥 회원 관리', '👥 User Management')),
          _actionTile(
            icon: Icons.people_rounded,
            iconColor: const Color(0xFF60A5FA),
            label: l.koEn('전체 회원 목록', 'All Users'),
            subtitle: l.koEn(
              'Firestore에서 회원 조회 · 검색 · 차단',
              'Browse, search, and ban users in Firestore',
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserManagementScreen()),
            ),
          ),
          _actionTile(
            icon: Icons.monitor_heart_rounded,
            iconColor: const Color(0xFF34D399),
            label: l.koEn('테스터 대시보드', 'Tester Dashboard'),
            subtitle: l.koEn(
              '실시간 테스터 현황 · 편지 · 지도 동기화 상태',
              'Real-time testers, letters, and map sync status',
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _TesterDashboardScreen()),
            ),
          ),
          const SizedBox(height: 8),

          // ──────────────────────────────────────────────────────────────────
          // 📊 통계
          // ──────────────────────────────────────────────────────────────────
          _sectionHeader(l.koEn('📊 통계', '📊 Stats')),
          _statsGrid(context, state),
          const SizedBox(height: 8),

          // ──────────────────────────────────────────────────────────────────
          // 🎛️ 운영 도구
          // ──────────────────────────────────────────────────────────────────
          _sectionHeader(l.koEn('🎛️ Operations', '🎛️ Operations')),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이벤트 모드
                _switchRow(
                  icon: Icons.celebration_rounded,
                  iconColor: AppColors.gold,
                  label: l.koEn('이벤트 모드', 'Event Mode'),
                  subtitle: l.koEn(
                    '무료 유저 한도를 프리미엄 수준으로 임시 상향',
                    'Temporarily raise free-user limits to premium level',
                  ),
                  value: state.adminEventMode,
                  onChanged: (v) {
                    state.setAdminEventMode(v);
                    _showSnack(
                      v
                          ? l.koEn('🎉 이벤트 모드 ON', '🎉 Event Mode ON')
                          : l.koEn('이벤트 모드 OFF', 'Event Mode OFF'),
                    );
                  },
                ),
                _divider(),
                // 배송 속도 배율
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.speed_rounded,
                        color: AppColors.teal,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  l.koEn('배송 속도 배율', 'Delivery Speed'),
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.teal.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _speedLabelAt(l, curSpeedIdx),
                                    style: const TextStyle(
                                      color: AppColors.teal,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.koEn(
                                '편지 이동 시뮬레이션 속도를 높임',
                                'Increase letter travel simulation speed',
                              ),
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.teal,
                      inactiveTrackColor: AppColors.teal.withValues(alpha: 0.2),
                      thumbColor: AppColors.teal,
                      overlayColor: AppColors.teal.withValues(alpha: 0.1),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: curSpeedIdx.toDouble(),
                      min: 0,
                      max: (_speedOptions.length - 1).toDouble(),
                      divisions: _speedOptions.length - 1,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        state.setAdminSpeedMultiplier(_speedOptions[v.round()]);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 시스템 편지 발송
          _actionTile(
            icon: Icons.mark_email_unread_rounded,
            iconColor: const Color(0xFF818CF8),
            label: l.koEn('시스템 편지 발송', 'Send System Letter'),
            subtitle: l.koEn(
              '현재 위치에서 내 받은 편지함으로 테스트 편지 생성',
              'Create a test letter to your inbox from current location',
            ),
            onTap: () => _sendSystemLetter(state),
          ),
          _divider(),
          // 🎯 ExactDrop 크레딧 충전 (브랜드 전용 유료 기능) — Build 108
          // 현재 잔고 + "100 충전" / "1000 충전" / "초기화" 버튼 3개.
          // 실제 결제 연동은 후속. 관리자 수동 충전으로 운영.
          _actionTile(
            icon: Icons.location_searching_rounded,
            iconColor: AppColors.gold,
            label: l.koEn(
              '🎯 ExactDrop 크레딧',
              '🎯 ExactDrop Credits',
            ),
            subtitle: l.koEn(
              '현재 잔고 ${state.brandExactDropCredits}통 · 100통 ₩10,000 패키지',
              'Current balance ${state.brandExactDropCredits} · 100-pack ₩10,000',
            ),
            trailing: _badge(
              '${state.brandExactDropCredits}',
              AppColors.gold,
            ),
            onTap: () => _showExactDropGrantSheet(state),
          ),
          const SizedBox(height: 8),

          // ──────────────────────────────────────────────────────────────────
          // 🛡️ 콘텐츠 관리
          // ──────────────────────────────────────────────────────────────────
          _sectionHeader(l.koEn('🛡️ 콘텐츠 관리', '🛡️ Content Moderation')),
          // ── 신고 접수 (임시 차단) 대기 목록 ──
          if (state.adminTempBlockedCount > 0) ...[
            _actionTile(
              icon: Icons.pending_actions_rounded,
              iconColor: Colors.orange,
              label: l.koEn('⏳ 검토 대기 (임시 차단)', '⏳ Pending Review (Temp Blocked)'),
              subtitle: l.koEn(
                '${state.adminTempBlockedCount}명 — 신고 접수 후 관리자 검토 대기 중',
                '${state.adminTempBlockedCount} users — awaiting admin review after report',
              ),
              trailing: _badge('${state.adminTempBlockedCount}', Colors.orange),
              onTap: () => _showTempBlockedSenders(state),
            ),
            const SizedBox(height: 4),
          ],
          _actionTile(
            icon: Icons.flag_rounded,
            iconColor: AppColors.warning,
            label: l.koEn('신고된 편지 목록', 'Reported Letters'),
            subtitle: l.koEn(
              '${state.adminReportedCount}건의 신고된 편지',
              '${state.adminReportedCount} reported letters',
            ),
            trailing: state.adminReportedCount > 0
                ? _badge('${state.adminReportedCount}', AppColors.warning)
                : null,
            onTap: () => _showReportedLetters(state),
          ),
          const SizedBox(height: 4),
          _actionTile(
            icon: Icons.block_rounded,
            iconColor: AppColors.error,
            label: l.koEn('차단된 발신자 목록', 'Blocked Senders'),
            subtitle: l.koEn(
              '${state.adminBlockedCount}명 영구 차단 중',
              '${state.adminBlockedCount} permanently blocked',
            ),
            trailing: state.adminBlockedCount > 0
                ? _badge('${state.adminBlockedCount}', AppColors.error)
                : null,
            onTap: () => _showBlockedSenders(state),
          ),
          if (state.adminBlockedCount > 0) ...[
            const SizedBox(height: 4),
            _actionTile(
              icon: Icons.clear_all_rounded,
              iconColor: AppColors.textMuted,
              label: l.koEn('차단 목록 전체 초기화', 'Clear All Blocks'),
              subtitle: l.koEn('모든 차단 해제', 'Unblock everyone'),
              onTap: () => _confirmAction(
                title: l.koEn('차단 목록 초기화', 'Reset Block List'),
                content: l.koEn(
                  '모든 차단을 해제합니다. 계속할까요?',
                  'This will unblock all users. Continue?',
                ),
                isDanger: true,
                onConfirm: () {
                  state.adminClearBlockList();
                  _showSnack(
                    l.koEn('차단 목록이 초기화됐어요', 'Block list has been reset'),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 8),

          // ──────────────────────────────────────────────────────────────────
          // 🔧 디버그 도구
          // ──────────────────────────────────────────────────────────────────
          _sectionHeader(l.koEn('🔧 디버그 도구', '🔧 Debug Tools')),
          _actionTile(
            icon: Icons.local_shipping_rounded,
            iconColor: AppColors.success,
            label: l.koEn('모든 편지 즉시 도착', 'Deliver All Letters Now'),
            subtitle: l.koEn(
              '이동 중인 ${state.adminInTransitCount}개 편지 강제 배송',
              'Force-deliver ${state.adminInTransitCount} in-transit letters',
            ),
            onTap: state.adminInTransitCount == 0
                ? null
                : () => _confirmAction(
                    title: l.koEn('모든 편지 즉시 도착', 'Deliver All Letters Now'),
                    content: l.koEn(
                      '이동 중인 ${state.adminInTransitCount}개 편지를 즉시 도착 처리합니다.',
                      'Deliver ${state.adminInTransitCount} in-transit letters immediately.',
                    ),
                    onConfirm: () {
                      state.adminForceDeliverAll();
                      _showSnack(
                        l.koEn(
                          '✅ ${state.adminInTransitCount}개 편지 배송 완료',
                          '✅ Delivered ${state.adminInTransitCount} letters',
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 4),
          _actionTile(
            icon: Icons.refresh_rounded,
            iconColor: AppColors.gold,
            label: l.koEn('일일 발송 카운터 리셋', 'Reset Daily Send Counter'),
            subtitle: l.koEn('오늘 발송 횟수를 0으로 초기화', 'Set today send count to 0'),
            onTap: () => _confirmAction(
              title: l.koEn('일일 카운터 리셋', 'Reset Daily Counter'),
              content: l.koEn(
                '오늘 발송 횟수를 0으로 초기화합니다.',
                'Reset today send count to 0.',
              ),
              onConfirm: () {
                state.adminResetDailyCount();
                _showSnack(l.koEn('✅ 일일 카운터 리셋 완료', '✅ Daily counter reset'));
              },
            ),
          ),
          const SizedBox(height: 4),
          _actionTile(
            icon: Icons.calendar_today_rounded,
            iconColor: AppColors.gold,
            label: l.koEn('월간 발송 카운터 리셋', 'Reset Monthly Send Counter'),
            subtitle: l.koEn(
              '이번 달 발송 횟수를 0으로 초기화',
              'Set this month send count to 0',
            ),
            onTap: () => _confirmAction(
              title: l.koEn('월간 카운터 리셋', 'Reset Monthly Counter'),
              content: l.koEn(
                '이번 달 발송 횟수를 0으로 초기화합니다.',
                'Reset this month send count to 0.',
              ),
              onConfirm: () {
                state.adminResetMonthlyCount();
                _showSnack(l.koEn('✅ 월간 카운터 리셋 완료', '✅ Monthly counter reset'));
              },
            ),
          ),
          const SizedBox(height: 4),
          _actionTile(
            icon: Icons.inbox_rounded,
            iconColor: AppColors.error,
            label: l.koEn('받은 편지함 비우기', 'Clear Inbox'),
            subtitle: l.koEn('받은 편지함의 모든 편지 삭제', 'Delete all inbox letters'),
            onTap: state.adminInboxCount == 0
                ? null
                : () => _confirmAction(
                    title: l.koEn('받은 편지함 비우기', 'Clear Inbox'),
                    content: l.koEn(
                      '받은 편지함의 ${state.adminInboxCount}개 편지가 모두 삭제됩니다.',
                      'Delete all ${state.adminInboxCount} letters from inbox.',
                    ),
                    isDanger: true,
                    onConfirm: () {
                      state.adminClearInbox();
                      _showSnack(l.koEn('🗑️ 받은 편지함 비움', '🗑️ Inbox cleared'));
                    },
                  ),
          ),
          const SizedBox(height: 4),
          _actionTile(
            icon: Icons.delete_sweep_rounded,
            iconColor: AppColors.error,
            label: l.koEn('모든 편지 전체 삭제', 'Clear All Letters'),
            subtitle: l.koEn(
              '받은 편지 + 보낸 편지 + 지도 위 편지 전부 삭제',
              'Delete inbox + sent + map letters',
            ),
            onTap: (state.adminInboxCount == 0 &&
                    state.adminTotalSent == 0 &&
                    state.worldLetters.isEmpty)
                ? null
                : () => _confirmAction(
                    title: l.koEn('모든 편지 삭제', 'Clear All Letters'),
                    content: l.koEn(
                      '받은 편지 ${state.adminInboxCount}개, 보낸 편지 ${state.adminTotalSent}개, 지도 편지 ${state.worldLetters.length}개가 모두 삭제됩니다.',
                      'Delete ${state.adminInboxCount} inbox, ${state.adminTotalSent} sent, ${state.worldLetters.length} map letters.',
                    ),
                    isDanger: true,
                    onConfirm: () {
                      state.adminClearAllLetters();
                      _showSnack(l.koEn('🗑️ 모든 편지 삭제 완료', '🗑️ All letters cleared'));
                    },
                  ),
          ),
          const SizedBox(height: 4),
          _actionTile(
            icon: Icons.emoji_events_outlined,
            iconColor: AppColors.textMuted,
            label: l.koEn('활동 점수 초기화', 'Reset Activity Score'),
            subtitle: l.koEn(
              '타워 높이 및 점수를 0으로 초기화',
              'Reset tower height and score',
            ),
            onTap: () => _confirmAction(
              title: l.koEn('활동 점수 초기화', 'Reset Activity Score'),
              content: l.koEn(
                '모든 활동 점수(받은 편지, 답장, 좋아요 등)가 초기화됩니다.',
                'All activity scores (received, replies, likes, etc.) will reset.',
              ),
              isDanger: true,
              onConfirm: () {
                state.adminResetActivityScore();
                _showSnack(l.koEn('✅ 활동 점수 초기화 완료', '✅ Activity score reset'));
              },
            ),
          ),
          const SizedBox(height: 8),

          // ──────────────────────────────────────────────────────────────────
          // 👤 계정 도구
          // ──────────────────────────────────────────────────────────────────
          _sectionHeader(l.koEn('👤 계정 도구', '👤 Account Tools')),
          _card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.koEn('현재 등급', 'Current Tier'),
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        user.isBrand
                            ? '🏷️ Brand'
                            : user.isPremium
                            ? '👑 Premium'
                            : '⭐ Free',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        user.email ?? user.username,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l.koEn('등급 변경', 'Change Tier'),
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _tierButton(
                          '⭐ Free',
                          isActive: !user.isPremium && !user.isBrand,
                          color: AppColors.textSecondary,
                          onTap: () => _confirmAction(
                            title: l.koEn('Free로 변경', 'Switch to Free'),
                            content: l.koEn(
                              '계정을 무료 등급으로 변경합니다.',
                              'Switch account to Free tier.',
                            ),
                            isDanger: true,
                            onConfirm: () {
                              purchase.debugSetTier(
                                isPremium: false,
                                isBrand: false,
                              );
                              state.syncPremiumStatus(
                                isPremium: false,
                                isBrand: false,
                              );
                              _showSnack(
                                l.koEn(
                                  '⭐ Free 등급으로 변경됨',
                                  '⭐ Switched to Free tier',
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _tierButton(
                          '👑 Premium',
                          isActive: user.isPremium && !user.isBrand,
                          color: AppColors.gold,
                          onTap: () {
                            purchase.debugSetTier(
                              isPremium: true,
                              isBrand: false,
                            );
                            state.syncPremiumStatus(
                              isPremium: true,
                              isBrand: false,
                            );
                            _showSnack(
                              l.koEn(
                                '👑 Premium 등급으로 변경됨',
                                '👑 Switched to Premium tier',
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _tierButton(
                          '🏷️ Brand',
                          isActive: user.isBrand,
                          color: const Color(0xFFA78BFA),
                          onTap: () {
                            purchase.debugSetTier(
                              isPremium: true,
                              isBrand: true,
                            );
                            state.syncPremiumStatus(
                              isPremium: true,
                              isBrand: true,
                            );
                            _showSnack(
                              l.koEn(
                                '🏷️ Brand 등급으로 변경됨',
                                '🏷️ Switched to Brand tier',
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 발송 현황
          _card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.koEn('발송 현황', 'Sending Status'),
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  _statRow(
                    l.koEn('오늘 발송', 'Sent Today'),
                    '${state.todaySentCount} / ${state.dailySendLimit}',
                  ),
                  _statRow(
                    l.koEn('이번 달 발송', 'Sent This Month'),
                    '${state._monthlySentCountAdmin} / ${state.monthlySendLimit}',
                  ),
                  _statRow(
                    l.koEn('특송 (오늘)', 'Express (Today)'),
                    '${state.todayPremiumExpressSentCount} / ${state.premiumExpressDailyLimit}',
                  ),
                  _statRow(
                    l.koEn('초대 보상 크레딧', 'Invite Reward Credits'),
                    l.koEn(
                      '${state.inviteRewardCredits}통',
                      '${state.inviteRewardCredits} letters',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 🎯 ExactDrop 크레딧 충전 시트 ────────────────────────────────────────
  /// 브랜드가 유료로 "정확 좌표 드롭" 을 쓸 수 있게 관리자가 수동 크레딧 충전.
  /// 현재 로컬 디바이스 잔고만 조정 — 실제 결제·서버 동기화는 후속 작업.
  void _showExactDropGrantSheet(AppState state) {
    final l = _l10n(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_searching_rounded,
                      color: AppColors.gold,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.koEn(
                          '🎯 ExactDrop 크레딧 충전',
                          '🎯 Grant ExactDrop Credits',
                        ),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l.koEn(
                    '현재 잔고 · ${state.brandExactDropCredits}통',
                    'Current balance · ${state.brandExactDropCredits}',
                  ),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _grantButton(
                  label: l.koEn('+ 100통 (₩10,000)', '+ 100 (₩10,000)'),
                  color: AppColors.gold,
                  onTap: () async {
                    await state.adminGrantExactDropCredits(100);
                    if (!sheetCtx.mounted) return;
                    Navigator.pop(sheetCtx);
                    _showSnack(
                      l.koEn('🎯 +100통 충전됨', '🎯 +100 credits granted'),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _grantButton(
                  label: l.koEn('+ 1,000통 (₩100,000)', '+ 1,000 (₩100,000)'),
                  color: AppColors.teal,
                  onTap: () async {
                    await state.adminGrantExactDropCredits(1000);
                    if (!sheetCtx.mounted) return;
                    Navigator.pop(sheetCtx);
                    _showSnack(
                      l.koEn('🎯 +1,000통 충전됨', '🎯 +1,000 credits granted'),
                    );
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () async {
                    // 초기화 — 현재 잔고 전체 차감 (부호 반대로 adminGrant 호출 불가
                    // 하므로 SharedPreferences 직접 조작 방식은 state API 상 없음.
                    // 대신 consumeExactDropCredit 를 반복 호출해 0 으로 만듦.)
                    while (state.brandExactDropCredits > 0) {
                      final ok = await state.consumeExactDropCredit();
                      if (!ok) break;
                    }
                    if (!sheetCtx.mounted) return;
                    Navigator.pop(sheetCtx);
                    _showSnack(
                      l.koEn('🎯 크레딧 초기화됨', '🎯 Credits reset to 0'),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.textMuted,
                      width: 0.8,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: Text(
                    l.koEn('초기화 (0 으로)', 'Reset to 0'),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.koEn(
                    '* 실제 결제 연동은 후속 작업. 현재는 관리자 수동 충전만 지원.',
                    '* Real-payment wiring is a follow-up. Manual grant only for now.',
                  ),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _grantButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.bgDeep,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: const Size.fromHeight(48),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ── 시스템 편지 발송 ────────────────────────────────────────────────────────
  void _sendSystemLetter(AppState state) {
    final l = _l10n(context);
    final ctrl = TextEditingController(
      text: l.koEn(
        '📮 Message in a Bottle 팀에서 드리는 특별 메시지입니다.\n\n세계 어딘가의 누군가가 당신에게 편지를 보냈어요. 오늘도 좋은 하루 되세요! 🌊',
        '📮 A special message from the Message in a Bottle team.\n\nSomeone, somewhere in the world sent you a letter. Have a wonderful day! 🌊',
      ),
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.mark_email_unread_rounded,
              color: Color(0xFF818CF8),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              l.koEn('시스템 편지 발송', 'Send System Letter'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: l.koEn('내용을 입력하세요...', 'Enter message...'),
            hintStyle: const TextStyle(color: AppColors.textMuted),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF1F2D44)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.teal),
            ),
            fillColor: AppColors.bgSurface,
            filled: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l.koEn('취소', 'Cancel'),
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              final content = ctrl.text.trim();
              if (content.isEmpty) return;
              state.adminAddSystemLetter(content);
              Navigator.pop(context);
              _showSnack(
                l.koEn(
                  '📮 시스템 편지가 받은 편지함에 추가됐어요',
                  '📮 System letter added to inbox',
                ),
              );
            },
            child: Text(
              l.koEn('발송', 'Send'),
              style: TextStyle(
                color: Color(0xFF818CF8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 신고된 편지 목록 ────────────────────────────────────────────────────────
  void _showReportedLetters(AppState state) {
    final l = _l10n(context);
    final letters = state.adminReportedLetters;
    if (letters.isEmpty) {
      _showSnack(l.koEn('신고된 편지가 없어요', 'No reported letters'));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                l.koEn('🚩 신고된 편지', '🚩 Reported Letters'),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: letters.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final l = letters[i];
                  return _reportedLetterCard(l, state, ctx, _l10n(context));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportedLetterCard(
    Letter l,
    AppState state,
    BuildContext sheetCtx,
    AppL10n t,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l.senderCountryFlag, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l.isAnonymous ? t.koEn('익명', 'Anonymous') : l.senderName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _badge(
                t.koEn('신고 ${l.reportCount}회', '${l.reportCount} reports'),
                AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    state.adminClearLetterReport(l.id);
                    Navigator.pop(sheetCtx);
                    _showSnack(t.koEn('✅ 신고 해제됨', '✅ Report cleared'));
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    side: const BorderSide(color: AppColors.teal),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    t.koEn('신고 해제', 'Clear Report'),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _confirmAction(
                    title: t.koEn('발신자 차단', 'Block Sender'),
                    content: t.koEn(
                      '${l.isAnonymous ? '익명' : l.senderName}의 모든 편지를 차단합니다.',
                      'Block all letters from ${l.isAnonymous ? 'Anonymous' : l.senderName}.',
                    ),
                    isDanger: true,
                    onConfirm: () {
                      state.adminBlockSender(l.senderId);
                      Navigator.pop(sheetCtx);
                      _showSnack(t.koEn('🚫 발신자 차단됨', '🚫 Sender blocked'));
                    },
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    t.koEn('차단', 'Block'),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 임시 차단 (검토 대기) 발신자 목록 ────────────────────────────────────────
  void _showTempBlockedSenders(AppState state) {
    final l = _l10n(context);
    final ids = state.tempBlockedSenderIds.toList();
    if (ids.isEmpty) {
      _showSnack(l.koEn('검토 대기 중인 사용자가 없어요', 'No users pending review'));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l.koEn('⏳ 검토 대기 (임시 차단)', '⏳ Pending Review'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l.koEn(
                  '신고 접수 후 관리자 검토 대기 중인 사용자입니다.\n영구 차단 또는 무혐의 처리를 선택하세요.',
                  'Users temporarily blocked after a report.\nChoose to permanently block or dismiss.',
                ),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: ids.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: Color(0xFF1F2D44), height: 1),
                itemBuilder: (_, i) => ListTile(
                  leading: const Icon(
                    Icons.pending_actions_rounded,
                    color: Colors.orange,
                    size: 20,
                  ),
                  title: Text(
                    ids[i],
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    l.koEn('신고 접수 · 임시 차단 중', 'Reported · Temp blocked'),
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 무혐의 (임시 차단 해제)
                      TextButton(
                        onPressed: () {
                          state.adminDismissReport(ids[i]);
                          Navigator.pop(ctx);
                          _showSnack(
                            l.koEn('✅ 무혐의 처리: ${ids[i]}', '✅ Dismissed: ${ids[i]}'),
                          );
                        },
                        child: Text(
                          l.koEn('무혐의', 'Dismiss'),
                          style: const TextStyle(
                            color: AppColors.teal,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // 영구 차단
                      TextButton(
                        onPressed: () {
                          state.adminConfirmBlock(ids[i]);
                          Navigator.pop(ctx);
                          _showSnack(
                            l.koEn('🚫 영구 차단: ${ids[i]}', '🚫 Permanently blocked: ${ids[i]}'),
                          );
                        },
                        child: Text(
                          l.koEn('영구 차단', 'Block'),
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  // ── 차단된 발신자 목록 ──────────────────────────────────────────────────────
  void _showBlockedSenders(AppState state) {
    final l = _l10n(context);
    final ids = state.blockedSenderIds.toList();
    if (ids.isEmpty) {
      _showSnack(l.koEn('차단된 발신자가 없어요', 'No blocked senders'));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                l.koEn('🚫 차단된 발신자', '🚫 Blocked Senders'),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: ids.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: Color(0xFF1F2D44), height: 1),
                itemBuilder: (_, i) => ListTile(
                  leading: const Icon(
                    Icons.block_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  title: Text(
                    ids[i],
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: () {
                      state.adminUnblockSender(ids[i]);
                      Navigator.pop(ctx);
                      _showSnack(
                        l.koEn('차단 해제됨: ${ids[i]}', 'Unblocked: ${ids[i]}'),
                      );
                    },
                    child: Text(
                      l.koEn('해제', 'Unblock'),
                      style: TextStyle(
                        color: AppColors.teal,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── UI 위젯 헬퍼 ────────────────────────────────────────────────────────────
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.teal,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0xFF1F2D44), width: 1),
        ),
      ),
      child: child,
    );
  }

  Widget _statsGrid(BuildContext context, AppState state) {
    final l = _l10n(context);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: [
        _statCard(
          l.koEn('📤 총 발송', '📤 Total Sent'),
          l.koEn('${state.adminTotalSent}통', '${state.adminTotalSent} letters'),
          AppColors.gold,
        ),
        _statCard(
          l.koEn('📥 받은 편지함', '📥 Inbox'),
          l.koEn(
            '${state.adminInboxCount}통',
            '${state.adminInboxCount} letters',
          ),
          AppColors.teal,
        ),
        _statCard(
          l.koEn('✈️ 이동 중', '✈️ In Transit'),
          l.koEn(
            '${state.adminInTransitCount}통',
            '${state.adminInTransitCount} letters',
          ),
          const Color(0xFF818CF8),
        ),
        _statCard(
          l.koEn('🚩 신고', '🚩 Reports'),
          l.koEn(
            '${state.adminReportedCount}건',
            '${state.adminReportedCount} cases',
          ),
          AppColors.warning,
        ),
        _statCard(
          l.koEn('🚫 차단', '🚫 Blocked'),
          l.koEn(
            '${state.adminBlockedCount}명',
            '${state.adminBlockedCount} users',
          ),
          AppColors.error,
        ),
        _statCard(
          l.koEn('📊 발송 (오늘)', '📊 Sent (Today)'),
          l.koEn('${state.todaySentCount}통', '${state.todaySentCount} letters'),
          AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return _card(
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: onTap == null ? AppColors.textMuted : AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        trailing:
            trailing ??
            (onTap != null
                ? const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  )
                : null),
        onTap: onTap,
      ),
    );
  }

  Widget _switchRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.teal,
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.bgSurface,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      color: Color(0xFF1F2D44),
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _tierButton(
    String label, {
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isActive ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.2)
              : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color : color.withValues(alpha: 0.25),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? color : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// AppState 내부 필드 접근을 위한 extension (admin only)
extension AdminAppStateExt on AppState {
  int get _monthlySentCountAdmin =>
      monthlySendLimit - remainingMonthlySendCount;
}

// ══════════════════════════════════════════════════════════════════════════════
// 테스터 대시보드 — 모든 테스터 + 편지 실시간 관리
// ══════════════════════════════════════════════════════════════════════════════
class _TesterDashboardScreen extends StatefulWidget {
  const _TesterDashboardScreen();

  @override
  State<_TesterDashboardScreen> createState() => _TesterDashboardScreenState();
}

class _TesterDashboardScreenState extends State<_TesterDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _testers = [];
  List<Map<String, dynamic>> _letters = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final state = context.read<AppState>();
      final results = await Future.wait([
        state.adminFetchAllUsers(),
        state.adminFetchAllLetters(),
      ]);
      if (mounted) {
        setState(() {
          _testers = results[0];
          _letters = results[1];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTimeColors.of(context);
    return Scaffold(
      backgroundColor: colors.bgDeep,
      appBar: AppBar(
        backgroundColor: colors.bgDeep,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tester Dashboard',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textSecondary),
            onPressed: _fetchAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.teal,
          labelColor: AppColors.teal,
          unselectedLabelColor: AppColors.textMuted,
          tabs: [
            Tab(text: 'Testers (${_testers.length})'),
            Tab(text: 'Letters (${_letters.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _fetchAll, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTesterList(),
                    _buildLetterList(),
                  ],
                ),
    );
  }

  // ── 테스터 목록 탭 ────────────────────────────────────────────────────────────
  Widget _buildTesterList() {
    if (_testers.isEmpty) {
      return const Center(
          child: Text('No testers found',
              style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
      itemCount: _testers.length + 1, // +1 for summary card
      itemBuilder: (ctx, i) {
        if (i == 0) return _testerSummaryCard();
        final t = _testers[i - 1];
        return _testerCard(t);
      },
    );
  }

  Widget _testerSummaryCard() {
    final totalSent = _testers.fold<int>(
        0, (s, t) => s + ((t['sentCount'] as num?)?.toInt() ?? 0));
    final totalReceived = _testers.fold<int>(
        0, (s, t) => s + ((t['receivedCount'] as num?)?.toInt() ?? 0));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.teal.withValues(alpha: 0.15),
            AppColors.teal.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Testers', '${_testers.length}', Icons.people),
          _summaryItem('Letters', '${_letters.length}', Icons.mail),
          _summaryItem('Sent', '$totalSent', Icons.send),
          _summaryItem('Received', '$totalReceived', Icons.inbox),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.teal, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }

  Widget _testerCard(Map<String, dynamic> t) {
    final username = t['username'] as String? ?? '???';
    final flag = t['countryFlag'] as String? ?? '🌍';
    final country = t['country'] as String? ?? '';
    final sent = (t['sentCount'] as num?)?.toInt() ?? 0;
    final received = (t['receivedCount'] as num?)?.toInt() ?? 0;
    final reply = (t['replyCount'] as num?)?.toInt() ?? 0;
    final likes = (t['likeCount'] as num?)?.toInt() ?? 0;
    final updatedAt = t['updatedAt'] as String? ?? '';
    final id = t['id'] as String? ?? '';
    final towerName = t['customTowerName'] as String? ?? '';
    final isPremium = t['isPremium'] == true;
    final isBrand = t['isBrand'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bgCard.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$flag ', style: const TextStyle(fontSize: 22)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(username,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (isBrand) _badge('BRAND', AppColors.error),
                        if (isPremium && !isBrand)
                          _badge('PRO', const Color(0xFFFFD700)),
                      ],
                    ),
                    if (towerName.isNotEmpty)
                      Text(towerName,
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                    Text(country,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statChip('Sent', '$sent', Icons.send_rounded),
              const SizedBox(width: 8),
              _statChip('Received', '$received', Icons.inbox_rounded),
              const SizedBox(width: 8),
              _statChip('Reply', '$reply', Icons.reply_rounded),
              const SizedBox(width: 8),
              _statChip('Likes', '$likes', Icons.favorite_rounded),
            ],
          ),
          if (updatedAt.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Last active: ${_formatTime(updatedAt)}',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
          ],
          Text('ID: ${id.length > 20 ? '${id.substring(0, 20)}...' : id}',
              style: TextStyle(color: AppColors.textMuted, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.w800)),
    );
  }

  Widget _statChip(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: AppColors.textMuted),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            Text(label,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  // ── 편지 목록 탭 ──────────────────────────────────────────────────────────────
  Widget _buildLetterList() {
    if (_letters.isEmpty) {
      return const Center(
          child: Text('No letters found',
              style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
      itemCount: _letters.length,
      itemBuilder: (ctx, i) => _letterCard(_letters[i]),
    );
  }

  Widget _letterCard(Map<String, dynamic> lt) {
    final id = lt['id'] as String? ?? '';
    final sender = lt['senderName'] as String? ?? '???';
    final senderFlag = lt['senderCountryFlag'] as String? ?? '';
    final destFlag = lt['destinationCountryFlag'] as String? ?? '';
    final destCountry = lt['destinationCountry'] as String? ?? '';
    final destCity = lt['destinationCity'] as String? ?? '';
    final sentAt = lt['sentAt'] as String? ?? '';
    final status = lt['status'] as String? ?? 'inTransit';
    final content = lt['content'] as String? ?? '';
    final totalMin = (lt['estimatedTotalMinutes'] as num?)?.toInt() ?? 0;
    final letterType = lt['letterType'] as String? ?? 'normal';

    final statusColor = switch (status) {
      'inTransit' => const Color(0xFF60A5FA),
      'delivered' || 'read' => const Color(0xFF34D399),
      'deliveredFar' => const Color(0xFFFBBF24),
      _ => AppColors.textMuted,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$senderFlag→$destFlag ',
                  style: const TextStyle(fontSize: 16)),
              Expanded(
                child: Text('$sender → $destCountry${destCity.isNotEmpty ? ' ($destCity)' : ''}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(status.toUpperCase(),
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content.length > 120 ? '${content.substring(0, 120)}...' : content,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(_formatTime(sentAt),
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 10)),
              const Spacer(),
              if (letterType != 'normal')
                _badge(letterType.toUpperCase(), AppColors.teal),
              const SizedBox(width: 6),
              Text('${totalMin}min',
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 10)),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _confirmDeleteLetter(id),
                child: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteLetter(String letterId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Letter',
            style: TextStyle(
                color: AppColors.error, fontWeight: FontWeight.w700)),
        content: const Text('Remove this letter from the server?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final state = context.read<AppState>();
              await state.adminDeleteLetter(letterId);
              _fetchAll();
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  String _formatTime(String isoStr) {
    if (isoStr.isEmpty) return '';
    final dt = DateTime.tryParse(isoStr);
    if (dt == null) return isoStr;
    final local = dt.toLocal();
    return '${local.month}/${local.day} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
