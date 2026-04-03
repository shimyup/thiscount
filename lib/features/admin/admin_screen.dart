import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
  static const List<String> _speedLabels = [
    '×1 (기본)',
    '×2',
    '×5',
    '×10',
    '×30',
    '×60',
    '×100',
    '×500',
    '×1000',
  ];

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
            child: const Text(
              '취소',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(
              '확인',
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
    final state = context.watch<AppState>();
    final purchase = context.watch<PurchaseService>();
    final colors = AppTimeColors.of(context);
    final curSpeedIdx = _speedIndex(state.adminSpeedMultiplier);
    final user = state.currentUser;
    final isAllowedAdmin =
        kDebugMode &&
        user.email?.toLowerCase() == DebugConstants.testBrandEmail;

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
          title: const Text(
            '관리자 패널',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ),
        body: const Center(
          child: Text(
            '접근 권한이 없습니다.',
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
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              '관리자 패널',
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
          _sectionHeader('👥 회원 관리'),
          _actionTile(
            icon: Icons.people_rounded,
            iconColor: const Color(0xFF60A5FA),
            label: '전체 회원 목록',
            subtitle: 'Firestore에서 회원 조회 · 검색 · 차단',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserManagementScreen()),
            ),
          ),
          const SizedBox(height: 8),

          // ──────────────────────────────────────────────────────────────────
          // 📊 통계
          // ──────────────────────────────────────────────────────────────────
          _sectionHeader('📊 통계'),
          _statsGrid(state),
          const SizedBox(height: 8),

          // ──────────────────────────────────────────────────────────────────
          // 🎛️ 운영 도구
          // ──────────────────────────────────────────────────────────────────
          _sectionHeader('🎛️ 운영 도구'),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이벤트 모드
                _switchRow(
                  icon: Icons.celebration_rounded,
                  iconColor: AppColors.gold,
                  label: '이벤트 모드',
                  subtitle: '무료 유저 한도를 프리미엄 수준으로 임시 상향',
                  value: state.adminEventMode,
                  onChanged: (v) {
                    state.setAdminEventMode(v);
                    _showSnack(v ? '🎉 이벤트 모드 ON' : '이벤트 모드 OFF');
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
                                const Text(
                                  '배송 속도 배율',
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
                                    _speedLabels[curSpeedIdx],
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
                            const Text(
                              '편지 이동 시뮬레이션 속도를 높임',
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
            label: '시스템 편지 발송',
            subtitle: '현재 위치에서 내 받은 편지함으로 테스트 편지 생성',
            onTap: () => _sendSystemLetter(state),
          ),
          const SizedBox(height: 8),

          // ──────────────────────────────────────────────────────────────────
          // 🛡️ 콘텐츠 관리
          // ──────────────────────────────────────────────────────────────────
          _sectionHeader('🛡️ 콘텐츠 관리'),
          _actionTile(
            icon: Icons.flag_rounded,
            iconColor: AppColors.warning,
            label: '신고된 편지 목록',
            subtitle: '${state.adminReportedCount}건의 신고된 편지',
            trailing: state.adminReportedCount > 0
                ? _badge('${state.adminReportedCount}', AppColors.warning)
                : null,
            onTap: () => _showReportedLetters(state),
          ),
          const SizedBox(height: 4),
          _actionTile(
            icon: Icons.block_rounded,
            iconColor: AppColors.error,
            label: '차단된 발신자 목록',
            subtitle: '${state.adminBlockedCount}명 차단 중',
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
              label: '차단 목록 전체 초기화',
              subtitle: '모든 차단 해제',
              onTap: () => _confirmAction(
                title: '차단 목록 초기화',
                content: '모든 차단을 해제합니다. 계속할까요?',
                isDanger: true,
                onConfirm: () {
                  state.adminClearBlockList();
                  _showSnack('차단 목록이 초기화됐어요');
                },
              ),
            ),
          ],
          const SizedBox(height: 8),

          // ──────────────────────────────────────────────────────────────────
          // 🔧 디버그 도구
          // ──────────────────────────────────────────────────────────────────
          _sectionHeader('🔧 디버그 도구'),
          _actionTile(
            icon: Icons.local_shipping_rounded,
            iconColor: AppColors.success,
            label: '모든 편지 즉시 도착',
            subtitle: '이동 중인 ${state.adminInTransitCount}개 편지 강제 배송',
            onTap: state.adminInTransitCount == 0
                ? null
                : () => _confirmAction(
                    title: '모든 편지 즉시 도착',
                    content:
                        '이동 중인 ${state.adminInTransitCount}개 편지를 즉시 도착 처리합니다.',
                    onConfirm: () {
                      state.adminForceDeliverAll();
                      _showSnack('✅ ${state.adminInTransitCount}개 편지 배송 완료');
                    },
                  ),
          ),
          const SizedBox(height: 4),
          _actionTile(
            icon: Icons.refresh_rounded,
            iconColor: AppColors.gold,
            label: '일일 발송 카운터 리셋',
            subtitle: '오늘 발송 횟수를 0으로 초기화',
            onTap: () => _confirmAction(
              title: '일일 카운터 리셋',
              content: '오늘 발송 횟수를 0으로 초기화합니다.',
              onConfirm: () {
                state.adminResetDailyCount();
                _showSnack('✅ 일일 카운터 리셋 완료');
              },
            ),
          ),
          const SizedBox(height: 4),
          _actionTile(
            icon: Icons.calendar_today_rounded,
            iconColor: AppColors.gold,
            label: '월간 발송 카운터 리셋',
            subtitle: '이번 달 발송 횟수를 0으로 초기화',
            onTap: () => _confirmAction(
              title: '월간 카운터 리셋',
              content: '이번 달 발송 횟수를 0으로 초기화합니다.',
              onConfirm: () {
                state.adminResetMonthlyCount();
                _showSnack('✅ 월간 카운터 리셋 완료');
              },
            ),
          ),
          const SizedBox(height: 4),
          _actionTile(
            icon: Icons.inbox_rounded,
            iconColor: AppColors.error,
            label: '받은 편지함 비우기',
            subtitle: '받은 편지함의 모든 편지 삭제',
            onTap: state.adminInboxCount == 0
                ? null
                : () => _confirmAction(
                    title: '받은 편지함 비우기',
                    content: '받은 편지함의 ${state.adminInboxCount}개 편지가 모두 삭제됩니다.',
                    isDanger: true,
                    onConfirm: () {
                      state.adminClearInbox();
                      _showSnack('🗑️ 받은 편지함 비움');
                    },
                  ),
          ),
          const SizedBox(height: 4),
          _actionTile(
            icon: Icons.emoji_events_outlined,
            iconColor: AppColors.textMuted,
            label: '활동 점수 초기화',
            subtitle: '타워 높이 및 점수를 0으로 초기화',
            onTap: () => _confirmAction(
              title: '활동 점수 초기화',
              content: '모든 활동 점수(받은 편지, 답장, 좋아요 등)가 초기화됩니다.',
              isDanger: true,
              onConfirm: () {
                state.adminResetActivityScore();
                _showSnack('✅ 활동 점수 초기화 완료');
              },
            ),
          ),
          const SizedBox(height: 8),

          // ──────────────────────────────────────────────────────────────────
          // 👤 계정 도구
          // ──────────────────────────────────────────────────────────────────
          _sectionHeader('👤 계정 도구'),
          _card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '현재 등급',
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
                  const Text(
                    '등급 변경',
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
                            title: 'Free로 변경',
                            content: '계정을 무료 등급으로 변경합니다.',
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
                              _showSnack('⭐ Free 등급으로 변경됨');
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
                            _showSnack('👑 Premium 등급으로 변경됨');
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
                            _showSnack('🏷️ Brand 등급으로 변경됨');
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
                  const Text(
                    '발송 현황',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  _statRow(
                    '오늘 발송',
                    '${state.todaySentCount} / ${state.dailySendLimit}',
                  ),
                  _statRow(
                    '이번 달 발송',
                    '${state._monthlySentCountAdmin} / ${state.monthlySendLimit}',
                  ),
                  _statRow(
                    '특송 (오늘)',
                    '${state.todayPremiumExpressSentCount} / ${state.premiumExpressDailyLimit}',
                  ),
                  _statRow('초대 보상 크레딧', '${state.inviteRewardCredits}통'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 시스템 편지 발송 ────────────────────────────────────────────────────────
  void _sendSystemLetter(AppState state) {
    final ctrl = TextEditingController(
      text:
          '📮 Message in a Bottle 팀에서 드리는 특별 메시지입니다.\n\n세계 어딘가의 누군가가 당신에게 편지를 보냈어요. 오늘도 좋은 하루 되세요! 🌊',
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(
              Icons.mark_email_unread_rounded,
              color: Color(0xFF818CF8),
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              '시스템 편지 발송',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
          ],
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: const InputDecoration(
            hintText: '내용을 입력하세요...',
            hintStyle: TextStyle(color: AppColors.textMuted),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF1F2D44)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.teal),
            ),
            fillColor: AppColors.bgSurface,
            filled: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '취소',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              final content = ctrl.text.trim();
              if (content.isEmpty) return;
              state.adminAddSystemLetter(content);
              Navigator.pop(context);
              _showSnack('📮 시스템 편지가 받은 편지함에 추가됐어요');
            },
            child: const Text(
              '발송',
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
    final letters = state.adminReportedLetters;
    if (letters.isEmpty) {
      _showSnack('신고된 편지가 없어요');
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
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '🚩 신고된 편지',
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
                  return _reportedLetterCard(l, state, ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportedLetterCard(Letter l, AppState state, BuildContext sheetCtx) {
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
                  l.isAnonymous ? '익명' : l.senderName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _badge('신고 ${l.reportCount}회', AppColors.warning),
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
                    _showSnack('✅ 신고 해제됨');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    side: const BorderSide(color: AppColors.teal),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('신고 해제', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _confirmAction(
                    title: '발신자 차단',
                    content:
                        '${l.isAnonymous ? '익명' : l.senderName}의 모든 편지를 차단합니다.',
                    isDanger: true,
                    onConfirm: () {
                      state.adminBlockSender(l.senderId);
                      Navigator.pop(sheetCtx);
                      _showSnack('🚫 발신자 차단됨');
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
                  child: const Text('차단', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 차단된 발신자 목록 ──────────────────────────────────────────────────────
  void _showBlockedSenders(AppState state) {
    final ids = state.blockedSenderIds.toList();
    if (ids.isEmpty) {
      _showSnack('차단된 발신자가 없어요');
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
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '🚫 차단된 발신자',
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
                      _showSnack('차단 해제됨: ${ids[i]}');
                    },
                    child: const Text(
                      '해제',
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

  Widget _statsGrid(AppState state) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: [
        _statCard('📤 총 발송', '${state.adminTotalSent}통', AppColors.gold),
        _statCard('📥 받은 편지함', '${state.adminInboxCount}통', AppColors.teal),
        _statCard(
          '✈️ 이동 중',
          '${state.adminInTransitCount}통',
          const Color(0xFF818CF8),
        ),
        _statCard('🚩 신고', '${state.adminReportedCount}건', AppColors.warning),
        _statCard('🚫 차단', '${state.adminBlockedCount}명', AppColors.error),
        _statCard(
          '📊 발송 (오늘)',
          '${state.todaySentCount}통',
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
