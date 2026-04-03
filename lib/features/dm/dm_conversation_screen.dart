import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/direct_message.dart';
import '../../../state/app_state.dart';

class DmConversationScreen extends StatefulWidget {
  final String partnerId;
  final String partnerName;
  final String partnerFlag;

  const DmConversationScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
    required this.partnerFlag,
  });

  @override
  State<DmConversationScreen> createState() => _DmConversationScreenState();
}

class _DmConversationScreenState extends State<DmConversationScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().markDMsRead(widget.partnerId);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(AppState state) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // 프리미엄 권한 체크
    if (!state.canUseDM) {
      _showDMUnavailableDialog(state);
      return;
    }

    _controller.clear();
    final success = state.sendDM(widget.partnerId, text);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '발송 가능 쿼터가 부족해요. (DM ${state.dmPerLetterQuota}회 = 편지 1통 차감)',
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _showDMUnavailableDialog(AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Text('💌', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              'DM 이용 불가',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          state.dmUnavailableMessage,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인', style: TextStyle(color: AppColors.teal)),
          ),
        ],
      ),
    );
  }

  /// 차단 확인 다이얼로그
  void _showBlockDialog(AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Text('🚫', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              '사용자 차단',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          '${widget.partnerName}님을 차단하면 DM 대화가 종료되고\n해당 사용자의 편지도 더 이상 받지 않아요.\n\n차단하시겠어요?',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              '취소',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              state.blockDMSender(widget.partnerId);
              Navigator.pop(context); // DM 화면도 닫기
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.partnerName}님을 차단했어요.'),
                  backgroundColor: AppColors.bgCard,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              '차단',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 신고 사유 선택 다이얼로그
  void _showReportDialog(AppState state) {
    final reasons = ['스팸 / 광고', '욕설 / 혐오 표현', '불법 정보', '성희롱 / 음란물', '기타'];
    String? selectedReason;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Text('🚨', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                '사용자 신고',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.partnerName}님을 신고하는 이유를 선택해주세요.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              ...reasons.map(
                (r) => RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    r,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  value: r,
                  groupValue: selectedReason,
                  activeColor: AppColors.error,
                  onChanged: (v) => setDialogState(() => selectedReason = v),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '* 신고 후 해당 사용자는 자동으로 차단됩니다.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                '취소',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: selectedReason == null
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      state.reportDMSender(widget.partnerId, selectedReason!);
                      Navigator.pop(context); // DM 화면도 닫기
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '신고가 접수됐어요. ${widget.partnerName}님을 차단했습니다.',
                          ),
                          backgroundColor: AppColors.bgCard,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
              child: Text(
                '신고',
                style: TextStyle(
                  color: selectedReason == null
                      ? AppColors.textMuted
                      : AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        // 프리미엄 게이트: 비프리미엄 또는 브랜드 → 잠금 화면
        if (!state.canUseDM) {
          return _buildDMGateScreen(state);
        }

        final messages = state.getDMConversation(widget.partnerId);
        if (messages.any(
          (m) => !m.isRead && m.senderId != state.currentUser.id,
        )) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            state.markDMsRead(widget.partnerId);
          });
        }

        return Scaffold(
          backgroundColor: AppColors.bgDeep,
          appBar: AppBar(
            backgroundColor: AppColors.bgCard,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            title: Row(
              children: [
                Text(
                  widget.partnerFlag,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.partnerName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '⚡ 빠른 편지  •  ${state.dmCountUntilNextQuotaDeduction}회 후 쿼터 차감',
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // 차단·신고 팝업 메뉴
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                color: AppColors.bgCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'block') _showBlockDialog(state);
                  if (value == 'report') _showReportDialog(state);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(Icons.block_rounded, color: AppColors.error, size: 18),
                        SizedBox(width: 8),
                        Text(
                          '차단하기',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.flag_rounded, color: AppColors.error, size: 18),
                        SizedBox(width: 8),
                        Text(
                          '신고하기',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: const Color(0xFF1F2D44)),
            ),
          ),
          body: Column(
            children: [
              // 헤더 정보
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: AppColors.bgCard.withValues(alpha: 0.5),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${widget.partnerName}님과의 1:1 빠른 편지 대화예요. DM ${state.dmPerLetterQuota}회 = 편지 1통 쿼터 차감.',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 메시지 목록
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '💌',
                              style: TextStyle(fontSize: 48),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${widget.partnerName}님과 첫 대화를 시작해보세요',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (_, i) {
                          final msg = messages[i];
                          final isMe =
                              msg.senderId == state.currentUser.id;
                          return _buildMessageBubble(msg, isMe);
                        },
                      ),
              ),
              // 입력 바
              _buildInputBar(state),
            ],
          ),
        );
      },
    );
  }

  /// DM 권한 없을 때 보여주는 게이트 화면
  Widget _buildDMGateScreen(AppState state) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
        title: const Text(
          '빠른 편지 (DM)',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1F2D44)),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.12),
                ),
                child: const Center(
                  child: Text('💌', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '프리미엄 전용 기능',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                state.dmUnavailableMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    _gateFeatureRow('⚡', '즉시 전달 빠른 편지 (DM)'),
                    const SizedBox(height: 8),
                    _gateFeatureRow('📮', '하루 30통 편지 발송'),
                    const SizedBox(height: 8),
                    _gateFeatureRow('📅', '월 500통 발송'),
                    const SizedBox(height: 8),
                    _gateFeatureRow('🌏', '더 많은 인연 연결'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gateFeatureRow(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(DirectMessage msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  widget.partnerFlag,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.gold.withValues(alpha: 0.15)
                    : AppColors.bgCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: Border.all(
                  color: isMe
                      ? AppColors.gold.withValues(alpha: 0.3)
                      : const Color(0xFF1F2D44),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.content,
                    style: TextStyle(
                      color: isMe
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(msg.sentAt),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildInputBar(AppState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: const Border(top: BorderSide(color: Color(0xFF1F2D44))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF1F2D44)),
                ),
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: '빠른 편지 쓰기...',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (_) => _sendMessage(state),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(state),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.goldLight, AppColors.gold],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('✈️', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
