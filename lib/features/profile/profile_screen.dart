import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/purchase_service.dart';
import '../../../state/app_state.dart';
import '../../../models/user_profile.dart';
import '../../../widgets/shared_profile_dialogs.dart';
import '../premium/premium_screen.dart';
import 'stamp_album_screen.dart';

// Premium Screen을 간단히 라우팅하기 위한 프록시
class _PremiumScreenProxy extends StatelessWidget {
  const _PremiumScreenProxy();
  @override
  Widget build(BuildContext context) => const PremiumScreen();
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifyNearby = true;
  bool _loading = true;
  final ImagePicker _picker = ImagePicker();

  AppL10n _l10n(BuildContext context) =>
      AppL10n.of(context.read<AppState>().currentUser.languageCode);

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifyNearby = prefs.getBool('notify_nearby') ?? true;
      _loading = false;
    });
  }

  Future<void> _setNotifyNearby(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_nearby', value);
    setState(() => _notifyNearby = value);
  }

  // ── 닉네임 수정 (shared_profile_dialogs.dart로 위임) ──────────────────────
  void _editUsername(BuildContext ctx, AppState state) {
    showEditUsernameDialog(ctx, state);
  }

  // ── SNS 링크 수정 ──────────────────────────────────────────────────────────
  void _editSnsLink(BuildContext ctx, AppState state) {
    final l = _l10n(ctx);
    final _initialText = state.currentUser.socialLink ?? '';
    final ctrl = TextEditingController.fromValue(
      TextEditingValue(
        text: _initialText,
        selection: TextSelection.collapsed(offset: _initialText.length),
      ),
    );
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l.koEn('SNS 링크 수정', 'Edit SNS Link'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.url,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'https://instagram.com/...',
            hintStyle: TextStyle(color: AppColors.textMuted),
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
            child: Text(
              l.koEn('취소', 'Cancel'),
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              final link = ctrl.text.trim();
              await AuthService.updateProfile(socialLink: link);
              state.updateSocialLink(link.isEmpty ? null : link);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(
              l.koEn('저장', 'Save'),
              style: const TextStyle(color: AppColors.teal),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeProfileImage(BuildContext ctx, AppState state) async {
    final l = _l10n(ctx);
    await showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.teal,
                  ),
                  title: Text(
                    l.koEn('앨범에서 선택', 'Choose from Gallery'),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    final picked = await _picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1400,
                      maxHeight: 1400,
                      imageQuality: 90,
                    );
                    if (picked == null || !mounted) return;

                    final appDir = await getApplicationDocumentsDirectory();
                    final ext = picked.path.contains('.')
                        ? picked.path.split('.').last
                        : 'jpg';
                    final newPath =
                        '${appDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.$ext';
                    await File(picked.path).copy(newPath);

                    final oldPath = state.currentUser.profileImagePath;
                    state.updateProfileImage(newPath);
                    if (oldPath != null &&
                        oldPath.isNotEmpty &&
                        oldPath != newPath &&
                        oldPath.startsWith(appDir.path)) {
                      try {
                        final oldFile = File(oldPath);
                        if (await oldFile.exists()) await oldFile.delete();
                      } catch (_) {}
                    }
                    if (mounted) _showSnack(ctx, l.koEn('프로필 사진이 변경되었습니다', 'Profile photo has been updated'));
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                  title: Text(
                    l.koEn('기본 아바타로 변경', 'Use Default Avatar'),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    final oldPath = state.currentUser.profileImagePath;
                    state.updateProfileImage(null);
                    if (oldPath != null && oldPath.isNotEmpty) {
                      try {
                        final oldFile = File(oldPath);
                        if (await oldFile.exists()) await oldFile.delete();
                      } catch (_) {}
                    }
                    if (mounted) _showSnack(ctx, l.koEn('기본 아바타로 변경되었습니다', 'Switched to the default avatar'));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showThemeModeSelector(BuildContext ctx, AppState state) async {
    final l = _l10n(ctx);
    await showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l.koEn('화면 모드 선택', 'Select Display Mode'),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                RadioListTile<DisplayThemeMode>(
                  value: DisplayThemeMode.auto,
                  groupValue: state.displayThemeMode,
                  onChanged: (v) {
                    if (v == null) return;
                    state.updateDisplayThemeMode(v);
                    Navigator.pop(sheetCtx);
                  },
                  title: Text(
                    l.koEn('자동 (시간대)', 'Auto (Timezone)'),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    l.koEn('국가 시간에 따라 낮/밤 테마 자동 변경', 'Auto switch day/night theme by timezone'),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  activeColor: AppColors.gold,
                ),
                RadioListTile<DisplayThemeMode>(
                  value: DisplayThemeMode.light,
                  groupValue: state.displayThemeMode,
                  onChanged: (v) {
                    if (v == null) return;
                    state.updateDisplayThemeMode(v);
                    Navigator.pop(sheetCtx);
                  },
                  title: Text(
                    l.koEn('밝은 모드', 'Light Mode'),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    l.koEn('항상 낮 테마로 표시', 'Always use light theme'),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  activeColor: AppColors.gold,
                ),
                RadioListTile<DisplayThemeMode>(
                  value: DisplayThemeMode.dark,
                  groupValue: state.displayThemeMode,
                  onChanged: (v) {
                    if (v == null) return;
                    state.updateDisplayThemeMode(v);
                    Navigator.pop(sheetCtx);
                  },
                  title: Text(
                    l.koEn('다크 모드', 'Dark Mode'),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    l.koEn('항상 밤 테마로 표시', 'Always use dark theme'),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  activeColor: AppColors.gold,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── 비밀번호 변경 ──────────────────────────────────────────────────────────
  void _changePassword(BuildContext ctx) {
    final l = _l10n(ctx);
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l.koEn('비밀번호 변경', 'Change Password'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pwField(oldCtrl, l.koEn('현재 비밀번호', 'Current Password')),
            const SizedBox(height: 12),
            _pwField(
              newCtrl,
              l.koEn('새 비밀번호 (6자 이상)', 'New Password (min 6 chars)'),
            ),
            const SizedBox(height: 12),
            _pwField(confirmCtrl, l.koEn('새 비밀번호 확인', 'Confirm New Password')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l.koEn('취소', 'Cancel'),
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (newCtrl.text.length < 6) {
                _showSnack(
                  ctx,
                  l.koEn(
                    '비밀번호는 6자 이상이어야 합니다',
                    'Password must be at least 6 characters',
                  ),
                );
                return;
              }
              if (newCtrl.text != confirmCtrl.text) {
                _showSnack(
                  ctx,
                  l.koEn('새 비밀번호가 일치하지 않습니다', 'New passwords do not match'),
                );
                return;
              }
              final user = await AuthService.getCurrentUser();
              if (user == null) return;
              final err = await AuthService.login(
                username: user['username'] ?? '',
                password: oldCtrl.text,
                langCode: ctx.read<AppState>().currentUser.languageCode,
              );
              if (err != null) {
                if (ctx.mounted) {
                  _showSnack(
                    ctx,
                    l.koEn(
                      '현재 비밀번호가 올바르지 않습니다',
                      'Current password is incorrect',
                    ),
                  );
                }
                return;
              }
              await AuthService.updatePassword(newCtrl.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                _showSnack(
                  ctx,
                  l.koEn('비밀번호가 변경되었습니다 ✓', 'Password changed ✓'),
                );
              }
            },
            child: Text(
              l.koEn('변경', 'Update'),
              style: const TextStyle(color: AppColors.teal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pwField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.textMuted),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.teal),
        ),
      ),
    );
  }

  void _showSnack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildAvatarContent(UserProfile user) {
    final imagePath = user.profileImagePath;
    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (file.existsSync()) {
        return ClipOval(
          child: Image.file(file, fit: BoxFit.cover, width: 64, height: 64),
        );
      }
    }
    return Center(
      child: Text(
        user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: AppColors.bgDeep,
        ),
      ),
    );
  }

  // ── 로그아웃 ───────────────────────────────────────────────────────────────
  void _confirmLogout(BuildContext ctx) {
    final l = _l10n(ctx);
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l.koEn('로그아웃', 'Log Out'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l.koEn('정말 로그아웃 하시겠어요?', 'Are you sure you want to log out?'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l.koEn('취소', 'Cancel'),
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              await AuthService.logout();
              if (ctx.mounted) {
                Navigator.of(
                  ctx,
                ).pushNamedAndRemoveUntil('/auth', (_) => false);
              }
            },
            child: Text(l.koEn('로그아웃', 'Log Out'), style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // ── 회원탈퇴 ───────────────────────────────────────────────────────────────
  void _confirmDeleteAccount(BuildContext ctx) {
    final l = _l10n(ctx);
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.koEn('회원탈퇴', 'Delete Account'), style: const TextStyle(color: AppColors.error)),
        content: Text(
          l.koEn('계정을 삭제하면 모든 편지와 데이터가 영구적으로 사라집니다.\n정말 탈퇴하시겠어요?', 'Deleting your account will permanently remove all letters and data.\nAre you sure?'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l.koEn('취소', 'Cancel'),
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              await AuthService.deleteAccount();
              if (ctx.mounted) {
                Navigator.of(
                  ctx,
                ).pushNamedAndRemoveUntil('/auth', (_) => false);
              }
            },
            child: Text(l.koEn('탈퇴', 'Delete'), style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // ── 우표 앨범 배너 ────────────────────────────────────────────────────────
  Widget _buildStampAlbumBanner(BuildContext ctx, AppState state) {
    final l = _l10n(ctx);
    // 수집된 국가 수 계산
    final countrySet = <String>{};
    for (final letter in state.inbox) {
      countrySet.add(letter.senderCountry);
    }
    final countryCount = countrySet.length;

    return GestureDetector(
      onTap: () => Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => const StampAlbumScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A3A2A), Color(0xFF0D2219)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4),
                ),
              ),
              child: const Center(
                child: Text('🌍', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.koEn('우표 앨범', 'STAMP ALBUM'),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    countryCount > 0
                        ? l.koEn('$countryCount개국 우표 수집됨', '$countryCount countries collected')
                        : l.koEn('아직 수집된 우표 없음', 'No stamps collected yet'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.gold,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  // ── 명성 등급 카드 (Stitch AI 추천) ────────────────────────────────────────
  Widget _buildReputationCard(BuildContext ctx, UserProfile user) {
    final l = _l10n(ctx);
    final score = user.activityScore;
    final tier = score.tier;
    const tierColors = {
      'shack': Color(0xFF607D8B),
      'cottage': Color(0xFF8D6E63),
      'house': Color(0xFF66BB6A),
      'townhouse': Color(0xFF26A69A),
      'building': Color(0xFF42A5F5),
      'office': Color(0xFF7E57C2),
      'skyscraper': Color(0xFFEC407A),
      'supertall': Color(0xFFFF7043),
      'megatower': Color(0xFFFFCA28),
      'landmark': Color(0xFFD4AF37),
    };
    final tierColor = tierColors[tier.name] ?? AppColors.gold;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tierColor.withValues(alpha: 0.12),
            tierColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tierColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: tierColor.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(tier.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.koEn('명성 점수', 'REPUTATION SCORE'),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  score.reputationTitle,
                  style: TextStyle(
                    color: tierColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score.towerHeight.toStringAsFixed(0),
                style: TextStyle(
                  color: tierColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                l.koEn('점', 'pts'),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFollowSection(
    BuildContext ctx,
    AppState state,
    UserProfile user,
  ) {
    final l = _l10n(ctx);
    return DefaultTabController(
      length: 2,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1F2D44)),
        ),
        child: Column(
          children: [
            TabBar(
              indicatorColor: AppColors.gold,
              labelColor: AppColors.gold,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: '👥 ${l.koEn('팔로잉', 'Following')} ${user.followingIds.length}'),
                Tab(text: '🌟 ${l.koEn('팔로워', 'Followers')} ${user.followerIds.length}'),
              ],
            ),
            SizedBox(
              height: user.followingIds.isEmpty && user.followerIds.isEmpty
                  ? 100
                  : 200,
              child: TabBarView(
                children: [
                  _FollowListContent(
                    title: l.koEn('팔로잉', 'Following'),
                    userIds: user.followingIds,
                    sessions: state.chatSessions,
                  ),
                  _FollowListContent(
                    title: l.koEn('팔로워', 'Followers'),
                    userIds: user.followerIds,
                    sessions: state.chatSessions,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppState, PurchaseService>(
      builder: (ctx, state, purchase, _) {
        final l = _l10n(ctx);
        final user = state.currentUser;

        return Scaffold(
          backgroundColor: AppTimeColors.of(ctx).bgDeep,
          body: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.teal),
                )
              : CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(ctx, user, state, purchase),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // ① 4열 스탯 (A+C)
                          _buildFourStatRow(ctx, state, user),
                          const SizedBox(height: 10),
                          // ② 구독 + 잔여발송 빠른카드 (B+C)
                          _buildQuickCardsRow(ctx, state, user, purchase),
                          const SizedBox(height: 10),
                          // ③ 타워 등급 + 프로그레스바 (A+B)
                          _buildTowerProgressCard(ctx, user),
                          const SizedBox(height: 10),
                          // ④ 우표 앨범 배너 (A)
                          _buildStampAlbumBanner(ctx, state),
                          const SizedBox(height: 10),
                          // ⑤ 팔로잉/팔로워 탭
                          _buildFollowSection(ctx, state, user),
                          const SizedBox(height: 10),
                          // ── 계정 ──
                          _settingsGroup(l.koEn('계정', 'Account'), [
                            _groupTile(
                              icon: Icons.person_rounded,
                              label: l.koEn('닉네임', 'Nickname'),
                              trailing: Text(
                                user.username,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                              onTap: () => _editUsername(ctx, state),
                            ),
                            _groupTile(
                              icon: Icons.location_city_rounded,
                              label: l.koEn('타워 이름', 'Tower Name'),
                              trailing: Text(
                                user.customTowerName?.isNotEmpty == true
                                    ? user.customTowerName!
                                    : l.koEn('미설정', 'Not Set'),
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              onTap: () => showEditTowerNameDialog(ctx, state),
                            ),
                            _groupTile(
                              icon: Icons.account_circle_rounded,
                              label: l.koEn('프로필 사진', 'Profile Photo'),
                              trailing: Text(
                                user.profileImagePath?.isNotEmpty == true
                                    ? l.koEn('설정됨', 'Set')
                                    : l.koEn('기본', 'Default'),
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                              onTap: () => _changeProfileImage(ctx, state),
                            ),
                            _groupTile(
                              icon: Icons.link_rounded,
                              label: l.koEn('SNS 링크', 'SNS Link'),
                              trailing: Text(
                                user.socialLink?.isNotEmpty == true
                                    ? user.socialLink!
                                    : l.koEn('미설정', 'Not Set'),
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              onTap: () => _editSnsLink(ctx, state),
                            ),
                            _groupTile(
                              icon: Icons.lock_outline_rounded,
                              label: l.koEn('비밀번호 변경', 'Change Password'),
                              onTap: () => _changePassword(ctx),
                              isLast: true,
                            ),
                          ]),
                          // ── 공개 설정 ──
                          _settingsGroup(l.koEn('공개 설정', 'Privacy'), [
                            _groupSwitchTile(
                              icon: Icons.badge_rounded,
                              label: l.koEn('닉네임 공개', 'Show Nickname'),
                              subtitle: l.koEn('다른 사용자에게 닉네임 표시', 'Display nickname to other users'),
                              value: user.isUsernamePublic,
                              onChanged: (v) => state.updatePrivacySettings(
                                isUsernamePublic: v,
                              ),
                            ),
                            _groupSwitchTile(
                              icon: Icons.link_rounded,
                              label: l.koEn('SNS 링크 공개', 'Show SNS Link'),
                              subtitle: l.koEn('편지에 SNS 링크 노출 허용', 'Allow SNS link to appear in letters'),
                              value: user.isSnsPublic,
                              onChanged: (v) =>
                                  state.updatePrivacySettings(isSnsPublic: v),
                              isLast: true,
                            ),
                          ]),
                          // ── 알림 ──
                          _settingsGroup(l.koEn('알림', 'Notifications'), [
                            _groupSwitchTile(
                              icon: Icons.notifications_active_rounded,
                              label: l.koEn('근처 편지 알림', 'Nearby Letter Alert'),
                              subtitle: l.koEn('2km 이내에 편지가 도착하면 알림', 'Notify when a letter arrives within 2km'),
                              value: _notifyNearby,
                              onChanged: _setNotifyNearby,
                              isLast: true,
                            ),
                          ]),
                          // ── 화면 ──
                          _settingsGroup(l.koEn('화면', 'Display'), [
                            _groupTile(
                              icon: Icons.brightness_6_rounded,
                              label: l.koEn('화면 모드', 'Display Mode'),
                              trailing: Text(
                                state.displayThemeModeLabel,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                              onTap: () => _showThemeModeSelector(ctx, state),
                              isLast: true,
                            ),
                          ]),
                          // ── 앱 정보 ──
                          _settingsGroup(l.koEn('앱 정보', 'App Info'), [
                            _groupTile(
                              icon: Icons.info_outline_rounded,
                              label: l.koEn('버전', 'Version'),
                              trailing: const Text(
                                '1.0.0',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            _groupTile(
                              icon: Icons.public_rounded,
                              label: l.koEn('나라', 'Country'),
                              trailing: Text(
                                '${user.countryFlag} ${user.country}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                              isLast: true,
                            ),
                          ]),
                          // ── 계정 관리 ──
                          _settingsGroup(l.koEn('계정 관리', 'Account Management'), [
                            _groupTile(
                              icon: Icons.logout_rounded,
                              label: l.koEn('로그아웃', 'Log Out'),
                              iconColor: AppColors.textSecondary,
                              labelColor: AppColors.textSecondary,
                              onTap: () => _confirmLogout(ctx),
                            ),
                            _groupTile(
                              icon: Icons.delete_forever_rounded,
                              label: l.koEn('회원탈퇴', 'Delete Account'),
                              iconColor: AppColors.error,
                              labelColor: AppColors.error,
                              onTap: () => _confirmDeleteAccount(ctx),
                              isLast: true,
                            ),
                          ]),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  // ── 등급별 배경 색상 ────────────────────────────────────────────────────────
  static Color _tierColor(TowerTier tier) {
    switch (tier) {
      case TowerTier.shack:
        return const Color(0xFF607D8B);
      case TowerTier.cottage:
        return const Color(0xFF8D6E63);
      case TowerTier.house:
        return const Color(0xFF66BB6A);
      case TowerTier.townhouse:
        return const Color(0xFF26A69A);
      case TowerTier.building:
        return const Color(0xFF42A5F5);
      case TowerTier.office:
        return const Color(0xFF7E57C2);
      case TowerTier.skyscraper:
        return const Color(0xFFEC407A);
      case TowerTier.supertall:
        return const Color(0xFFFF7043);
      case TowerTier.megatower:
        return const Color(0xFFFFCA28);
      case TowerTier.landmark:
        return const Color(0xFFD4AF37);
    }
  }

  // ── SliverAppBar (프로필 헤더) — A+C 믹스 ─────────────────────────────────
  Widget _buildSliverAppBar(
    BuildContext ctx,
    UserProfile user,
    AppState state,
    PurchaseService purchase,
  ) {
    final tier = user.activityScore.tier;
    final tierClr = _tierColor(tier);
    final isBrand = purchase.isBrand || user.isBrand;
    final isPrem = isBrand || purchase.isPremium || user.isPremium;
    final planLabel = isBrand
        ? '🏷️ Brand'
        : isPrem
        ? '👑 Premium'
        : null;
    final planColor = isBrand ? const Color(0xFFFF8A5C) : AppColors.gold;

    return SliverAppBar(
      expandedHeight: 270,
      pinned: true,
      backgroundColor: AppTimeColors.of(ctx).bgDeep,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                tierClr.withValues(alpha: 0.22),
                tierClr.withValues(alpha: 0.06),
                AppTimeColors.of(ctx).bgDeep,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                // 아바타 (88px, 등급 색상 테두리 글로우)
                GestureDetector(
                  onTap: () => _changeProfileImage(ctx, state),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [tierClr.withValues(alpha: 0.9), tierClr],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: tierClr.withValues(alpha: 0.45),
                              blurRadius: 20,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: _buildAvatarContent(user),
                      ),
                      // 등급 뱃지 (우상단 — A방향)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.bgDeep,
                            shape: BoxShape.circle,
                            border: Border.all(color: tierClr, width: 1.5),
                          ),
                          child: Text(
                            tier.emoji,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      // 편집 버튼 (우하단)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.teal,
                            border: Border.all(
                              color: AppTimeColors.of(ctx).bgDeep,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // 닉네임 + 플랜 뱃지 (B방향)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (planLabel != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: planColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: planColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          planLabel,
                          style: TextStyle(
                            color: planColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                // 국가 + 명성 칭호 (A방향)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${user.countryFlag} ${user.country}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 1,
                      height: 11,
                      color: AppColors.textMuted.withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      user.activityScore.reputationTitle,
                      style: TextStyle(
                        color: tierClr,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      title: Text(
        _l10n(ctx).koEn('프로필', 'Profile'),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }

  // ── ① 4열 스탯 바 (A+C) ────────────────────────────────────────────────────
  Widget _buildFourStatRow(BuildContext ctx, AppState state, UserProfile user) {
    final l = _l10n(ctx);
    final score = user.activityScore;
    // 나라 수: 받은 편지 발송 국가
    final countrySet = state.inbox.map((l) => l.senderCountry).toSet();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          _stat4Cell('📬', '${score.sentCount}', l.koEn('보낸 편지', 'Sent')),
          _stat4Divider(),
          _stat4Cell('📥', '${score.receivedCount}', l.koEn('받은 편지', 'Received')),
          _stat4Divider(),
          _stat4Cell('🌍', '${countrySet.length}', l.koEn('방문 나라', 'Countries')),
          _stat4Divider(),
          _stat4Cell('👥', '${user.followerIds.length}', l.koEn('팔로워', 'Followers')),
        ],
      ),
    );
  }

  Widget _stat4Cell(String emoji, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _stat4Divider() {
    return Container(width: 1, height: 44, color: AppColors.bgSurface);
  }

  // ── ② 구독 카드 + 오늘 발송 잔여 카드 (B+C) ─────────────────────────────────
  Widget _buildQuickCardsRow(
    BuildContext ctx,
    AppState state,
    UserProfile user,
    PurchaseService purchase,
  ) {
    final isBrand = purchase.isBrand || user.isBrand;
    final isPremium = isBrand || purchase.isPremium || user.isPremium;
    final planName = isBrand
        ? '🏷️ Brand'
        : isPremium
        ? '👑 Premium'
        : '⭐ Free';
    final l = _l10n(ctx);
    final planPrice = isBrand
        ? l.koEn('₩99,000/월', '₩99,000/mo')
        : isPremium
        ? l.koEn('₩4,900/월', '₩4,900/mo')
        : l.koEn('무료', 'Free');
    final planColor = isBrand
        ? const Color(0xFFFF8A5C)
        : isPremium
        ? AppColors.gold
        : AppColors.textMuted;

    final remaining = state.remainingDailySendCount;
    final limit = state.dailySendLimit;
    final quotaPct = limit > 0 ? remaining / limit : 0.0;
    final quotaColor = quotaPct > 0.4
        ? AppColors.teal
        : quotaPct > 0.15
        ? const Color(0xFFFFCA28)
        : AppColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 구독 카드
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                ctx,
                MaterialPageRoute(builder: (_) => const _PremiumScreenProxy()),
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: planColor.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          l.koEn('구독 플랜', 'Subscription Plan'),
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted,
                          size: 14,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      planName,
                      style: TextStyle(
                        color: planColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      planPrice,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (!isPremium) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.goldLight, AppColors.gold],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l.koEn('업그레이드 →', 'Upgrade →'),
                          style: const TextStyle(
                            color: AppColors.bgDeep,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 오늘 발송 잔여 카드
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: quotaColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.koEn('오늘 발송', 'Today Quota'),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$remaining',
                          style: TextStyle(
                            color: quotaColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextSpan(
                          text: '/$limit',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: quotaPct,
                      minHeight: 5,
                      backgroundColor: AppColors.bgSurface,
                      valueColor: AlwaysStoppedAnimation<Color>(quotaColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.koEn('내일 자정 초기화', 'Resets at midnight'),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ③ 타워 등급 + 프로그레스바 (A+B) ─────────────────────────────────────
  Widget _buildTowerProgressCard(BuildContext ctx, UserProfile user) {
    final l = _l10n(ctx);
    final score = user.activityScore;
    final tier = score.tier;
    final tierClr = _tierColor(tier);
    final progress = score.tierProgress;
    final ptsLeft = (score.tierMax - score.towerHeight).clamp(
      0,
      double.infinity,
    );
    final isMax = tier == TowerTier.landmark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tierClr.withValues(alpha: 0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tierClr.withValues(alpha: 0.08), Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 등급 이모지 + 이름
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tierClr.withValues(alpha: 0.12),
                  border: Border.all(color: tierClr.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(tier.emoji, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.koEn('타워 등급', 'TOWER RANK'),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tier.label,
                      style: TextStyle(
                        color: tierClr,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      score.reputationTitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // 점수
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    score.towerHeight.toStringAsFixed(0),
                    style: TextStyle(
                      color: tierClr,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    l.koEn('점', 'pts'),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 프로그레스바
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.bgSurface,
              valueColor: AlwaysStoppedAnimation<Color>(tierClr),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isMax ? l.koEn('🏆 최고 등급 달성!', '🏆 Max rank achieved!') : tier.nextGoal,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              if (!isMax)
                Text(
                  l.koEn('${ptsLeft.toStringAsFixed(0)}pts 남음', '${ptsLeft.toStringAsFixed(0)}pts left'),
                  style: TextStyle(
                    color: tierClr,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCell(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.teal, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 40, color: AppColors.bgSurface);
  }

  // ── 섹션 헤더 ──────────────────────────────────────────────────────────────
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.teal,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ── 일반 타일 ──────────────────────────────────────────────────────────────
  Widget _tile({
    required IconData icon,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textSecondary, size: 22),
      title: Text(
        label,
        style: TextStyle(color: color ?? AppColors.textPrimary, fontSize: 15),
      ),
      trailing: trailing != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                trailing,
                const SizedBox(width: 4),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
              ],
            )
          : onTap != null
          ? const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 18,
            )
          : null,
      onTap: onTap,
      tileColor: Colors.transparent,
    );
  }

  // ── 스위치 타일 ────────────────────────────────────────────────────────────
  Widget _switchTile({
    required IconData icon,
    required String label,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(
        label,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.teal,
        inactiveThumbColor: AppColors.textMuted,
        inactiveTrackColor: AppColors.bgCard,
      ),
    );
  }

  // ── 카드형 설정 그룹 ─────────────────────────────────────────────────────
  Widget _settingsGroup(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.teal,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.textMuted.withValues(alpha: 0.1),
              ),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // ── 그룹 내 일반 타일 ────────────────────────────────────────────────────
  Widget _groupTile({
    required IconData icon,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    Color? labelColor,
    bool isLast = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: isLast
              ? const BorderRadius.vertical(bottom: Radius.circular(16))
              : BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.textSecondary).withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? AppColors.textSecondary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: labelColor ?? AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (trailing != null) ...[trailing, const SizedBox(width: 4)],
                if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 64),
            child: Divider(
              height: 1,
              color: AppColors.textMuted.withValues(alpha: 0.08),
            ),
          ),
      ],
    );
  }

  // ── 그룹 내 스위치 타일 ──────────────────────────────────────────────────
  Widget _groupSwitchTile({
    required IconData icon,
    required String label,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.textSecondary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
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
                inactiveTrackColor: AppColors.bgCard,
              ),
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 64),
            child: Divider(
              height: 1,
              color: AppColors.textMuted.withValues(alpha: 0.08),
            ),
          ),
      ],
    );
  }
}

class _FollowListContent extends StatelessWidget {
  final String title;
  final List<String> userIds;
  final Map<String, dynamic> sessions;

  const _FollowListContent({
    required this.title,
    required this.userIds,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context.select<AppState, String>((s) => s.currentUser.languageCode));
    if (userIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🔭',
              style: TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              title == l.koEn('팔로잉', 'Following')
                  ? l.koEn('팔로잉 중인 유저가 없어요', 'You are not following anyone yet')
                  : l.koEn('아직 팔로워가 없어요', 'No followers yet'),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: userIds.length,
      itemBuilder: (ctx, i) {
        final uid = userIds[i];
        final session = sessions[uid];
        final name = session?.partnerName ?? uid;
        final flag = session?.partnerFlag ?? '🌍';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (session != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text('💬', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FollowStatChip extends StatelessWidget {
  final String label;
  final int count;
  const _FollowStatChip({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}
