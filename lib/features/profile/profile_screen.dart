import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
// Build 175: ShareCardService 를 쓰면서 share_plus 직접 호출은 필요 없어짐.
import '../share/share_card_service.dart';

import '../progression/user_progress.dart';
import '../brand/brand_analytics_card.dart';
import '../brand/brand_checklist_card.dart';
import '../hunt_wallet/hunt_wallet_card.dart';
import '../journey/journey_card.dart';
import '../reflection/weekly_reflection_card.dart';
import '../streak/streak_badge.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/country_names.dart';
import '../../../core/localization/language_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
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
  bool _notifyDaily = false;
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
      _notifyDaily = prefs.getBool('notify_daily_letter') ?? false;
      _loading = false;
    });
  }

  Future<void> _setNotifyNearby(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_nearby', value);
    setState(() => _notifyNearby = value);
  }

  Future<void> _setNotifyDaily(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_daily_letter', value);
    setState(() => _notifyDaily = value);
    if (!mounted) return;
    final lang = context.read<AppState>().currentUser.languageCode;
    if (value) {
      await NotificationService.requestPermissions();
      await NotificationService.scheduleDailyLetterReminder(langCode: lang);
    } else {
      await NotificationService.cancelDailyLetterReminder();
    }
  }

  // ── 닉네임 수정 (shared_profile_dialogs.dart로 위임) ──────────────────────
  void _editUsername(BuildContext ctx, AppState state) {
    showEditUsernameDialog(ctx, state);
  }

  /// Build 155: 내 레벨·캐릭터 SNS 공유.
  /// Build 175: 텍스트-only → **1080×1920 이미지 카드** 로 업그레이드.
  /// ShareCardService.shareCharacterCard 로 위임. 실패 시 기존 텍스트 fallback.
  Future<void> _shareMyLevel(BuildContext ctx, AppState state) async {
    final l = AppL10n.of(state.currentUser.languageCode);
    final user = state.currentUser;
    final letterName =
        (user.customTowerName?.isNotEmpty == true)
            ? user.customTowerName!
            : user.username;
    final ok = await ShareCardService.shareCharacterCard(
      characterEmoji: state.currentCharacterEmoji,
      companionEmoji: state.activeCompanionEmoji,
      accessoryEmoji: state.activeAccessoryEmoji,
      level: state.currentLevel,
      levelLabel: state.levelLabel,
      letterName: letterName,
      daysSinceJoined: state.daysSinceJoined,
      collectedLetters: state.inbox.length,
      langCode: user.languageCode,
    );
    if (!ok && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(l.shareFailed),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ── SNS 링크 수정 ──────────────────────────────────────────────────────────
  void _editSnsLink(BuildContext ctx, AppState state) {
    final _pl = AppL10n.of(state.currentUser.languageCode);
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
          _pl.profileSnsLinkEdit,
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
              _pl.cancel,
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
            child: Text(_pl.save, style: const TextStyle(color: AppColors.teal)),
          ),
        ],
      ),
    );
  }

  Future<void> _changeProfileImage(BuildContext ctx, AppState state) async {
    final _pl = AppL10n.of(state.currentUser.languageCode);
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
                    _pl.profileSelectFromAlbum,
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
                    if (mounted) _showSnack(ctx, _pl.profilePhotoChanged);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                  title: Text(
                    _pl.profileChangeToDefaultAvatar,
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
                    if (mounted) _showSnack(ctx, _pl.profileDefaultAvatarChanged);
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
    final _pl = AppL10n.of(state.currentUser.languageCode);
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
                    _pl.profileSelectDisplayMode,
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
                    _pl.profileAutoTimezone,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    _pl.profileAutoTimezoneDesc,
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
                    _pl.profileLightMode,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    _pl.profileLightModeDesc,
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
                    _pl.profileDarkMode,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    _pl.profileDarkModeDesc,
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
    final _pl = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _pl.profileChangePassword,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pwField(oldCtrl, _pl.profileCurrentPassword),
            const SizedBox(height: 12),
            _pwField(newCtrl, _pl.profileNewPassword),
            const SizedBox(height: 12),
            _pwField(confirmCtrl, _pl.profileConfirmPassword),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              _pl.cancel,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (newCtrl.text.length < 6) {
                _showSnack(ctx, _pl.profilePasswordMinLength);
                return;
              }
              if (newCtrl.text != confirmCtrl.text) {
                _showSnack(ctx, _pl.profilePasswordMismatch);
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
                if (ctx.mounted) _showSnack(ctx, _pl.profileCurrentPasswordWrong);
                return;
              }
              await AuthService.updatePassword(newCtrl.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                _showSnack(ctx, _pl.profilePasswordChanged);
              }
            },
            child: Text(_pl.change, style: const TextStyle(color: AppColors.teal)),
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

  // ── 언어 변경 ──────────────────────────────────────────────────────────────
  void _showLanguagePicker(BuildContext ctx, AppState state) {
    final currentCode = state.currentUser.languageCode;
    final l = AppL10n.of(currentCode);
    final languages = LanguageConfig.languageNames.entries.toList();

    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l.settingsLanguage,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Divider(height: 1, color: AppColors.textMuted.withValues(alpha: 0.2)),
              SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.45,
                child: ListView.builder(
                  itemCount: languages.length,
                  itemBuilder: (_, i) {
                    final code = languages[i].key;
                    final name = languages[i].value;
                    final isSelected = code == currentCode;
                    return ListTile(
                      dense: true,
                      leading: isSelected
                          ? const Icon(Icons.check_circle, color: AppColors.teal, size: 20)
                          : const Icon(Icons.circle_outlined, color: AppColors.textMuted, size: 20),
                      title: Text(
                        name,
                        style: TextStyle(
                          color: isSelected ? AppColors.teal : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                      onTap: () {
                        state.updateProfile(languageCode: code);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 로그아웃 ───────────────────────────────────────────────────────────────
  void _confirmLogout(BuildContext ctx) {
    final _pl = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _pl.logout,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          _pl.profileLogoutMsg,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              _pl.cancel,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              // Firebase 세션 살아있을 때 마지막 위치 Firestore 반영 →
              // 다른 회원 지도에서 타워가 "마지막 접속 위치"로 유지됨
              await ctx.read<AppState>().snapshotUserForLogout();
              await AuthService.logout();
              if (ctx.mounted) {
                Navigator.of(
                  ctx,
                ).pushNamedAndRemoveUntil('/auth', (_) => false);
              }
            },
            child: Text(_pl.logout, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // ── 회원탈퇴 ───────────────────────────────────────────────────────────────
  void _confirmDeleteAccount(BuildContext ctx) {
    final _dl = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_dl.deleteAccount, style: const TextStyle(color: AppColors.error)),
        content: Text(
          _dl.profileDeleteAccountMsg,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              _dl.cancel,
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
            child: Text(_dl.withdraw, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // ── 우표 앨범 배너 ────────────────────────────────────────────────────────
  Widget _buildStampAlbumBanner(BuildContext ctx, AppState state) {
    final _sbl = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
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
                    _sbl.labelStampAlbum,
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    countryCount > 0
                        ? _sbl.profileStampCollected(countryCount)
                        : _sbl.profileNoStamps,
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
    final _rl = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
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
                  _rl.labelReputationScore,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  score.reputationTitleL(user.languageCode),
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
                _rl.unitPts,
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
    final _fl = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
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
                Tab(text: '👥 ${_fl.profileFollowing} ${user.followingIds.length}'),
                Tab(text: '🌟 ${_fl.profileFollowers} ${user.followerIds.length}'),
              ],
            ),
            SizedBox(
              height: user.followingIds.isEmpty && user.followerIds.isEmpty
                  ? 100
                  : 200,
              child: TabBarView(
                children: [
                  _FollowListContent(
                    title: _fl.profileFollowing,
                    emptyMsg: _fl.profileNoFollowing,
                    userIds: user.followingIds,
                    sessions: state.chatSessions,
                  ),
                  _FollowListContent(
                    title: _fl.profileFollowers,
                    emptyMsg: _fl.profileNoFollowers,
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
        final user = state.currentUser;
        final _lc = user.languageCode;
        final _l = AppL10n.of(_lc);

        return Scaffold(
          backgroundColor: AppTimeColors.of(ctx).bgDeep,
          body: _loading
              // Build 160: AppLoading.large — teal → gold 로 통일 (로더 색
              // 분산 해소). Center 로 감싸 full-screen 중앙 배치.
              ? AppLoading.large
              : CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(ctx, user, state, purchase),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // ① 4열 스탯 (A+C)
                          _buildFourStatRow(ctx, state, user),
                          const SizedBox(height: 12),
                          // ①-1 나의 헌트 기록 — Build 115 신규. "이번 달
                          // 얼마나 벌었나?" 감각을 만드는 메인 지표 카드.
                          // Brand 계정은 발송이 본업이라 픽업 지표가 비어있어
                          // 오해를 주므로 숨김 (Build 117). 브랜드 전용 집계는
                          // myRedeemedSentCount 등을 통한 별도 대시보드로
                          // 후속에서 분리.
                          if (!user.isBrand) ...[
                            const HuntWalletCard(
                              margin: EdgeInsets.symmetric(horizontal: 16),
                            ),
                            const SizedBox(height: 12),
                          ],
                          // Build 138: Brand 전용 ROI 대시보드. 발송·픽업·사용
                          // 집계 + 전환율 + 국가별 상위 리스트. Firestore 에서
                          // 실시간 조회하므로 광고주가 캠페인 효과를 볼 수 있음.
                          if (user.isBrand) ...[
                            // Build 156: 신규 Brand 온보딩 체크리스트
                            // (3/3 완료 시 자동 숨김).
                            const BrandChecklistCard(),
                            const SizedBox(height: 12),
                            const BrandAnalyticsCard(),
                            const SizedBox(height: 12),
                          ],
                          // ①-2 나의 여정 카드 — 누적 지표가 있을 때만 표시
                          const JourneyCard(
                            margin: EdgeInsets.symmetric(horizontal: 16),
                          ),
                          const SizedBox(height: 12),
                          // ①-4 이번 주 회고 — 일요일 + 발송 이력 있을 때만
                          const WeeklyReflectionCard(),
                          // ② 구독 + 잔여발송 빠른카드 (B+C)
                          _buildQuickCardsRow(ctx, state, user, purchase),
                          const SizedBox(height: 12),
                          // Build 178: XP 레벨 바 + 타워 진척 카드는 Free/Premium
                          // 유저의 경우 레터 탭 hero 에 이미 표시됨 → 여기선 숨겨
                          // 프로필 수직 밀도 감소. Brand 만 남겨 타워 정체성 유지.
                          if (user.isBrand) ...[
                            _buildXpLevelCard(ctx, state),
                            const SizedBox(height: 12),
                            _buildTowerProgressCard(ctx, user),
                            const SizedBox(height: 12),
                          ],
                          // ④ 우표 앨범 배너 — Build 185: Brand 숨김.
                          // Brand 는 ROI 대시보드가 프로필 주력이고 우표 수집은
                          // Free/Premium 게임플레이 요소.
                          if (!user.isBrand) ...[
                            _buildStampAlbumBanner(ctx, state),
                            const SizedBox(height: 12),
                          ],
                          // ⑤ 팔로잉/팔로워 탭
                          _buildFollowSection(ctx, state, user),
                          const SizedBox(height: 16),
                          // Build 183: "계정 설정" 섹션을 하나의 ExpansionTile
                          // 뒤로 숨겨 프로필 스캔을 가볍게. 탭하면 아래 계정/
                          // 공개/알림/화면/앱정보/계정관리 전체가 펼쳐진다.
                          // 기존 섹션 구조는 유지 → 필요할 때만 꺼냄.
                          _SettingsCollapseButton(
                            label: _l.profileSettingsCollapseLabel,
                            sublabel: _l.profileSettingsCollapseSublabel,
                            children: [
                          // ── 계정 ──
                          _settingsGroup(_l.profileAccountSection, [
                            _groupTile(
                              icon: Icons.person_rounded,
                              label: _l.profileNickname,
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
                              label: _l.profileTowerName,
                              trailing: Text(
                                user.customTowerName?.isNotEmpty == true
                                    ? user.customTowerName!
                                    : _l.profileNotSet,
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
                              label: _l.profilePhoto,
                              trailing: Text(
                                user.profileImagePath?.isNotEmpty == true
                                    ? _l.profilePhotoSet
                                    : _l.profilePhotoDefault,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                              onTap: () => _changeProfileImage(ctx, state),
                            ),
                            _groupTile(
                              icon: Icons.link_rounded,
                              label: _l.profileSnsLink,
                              trailing: Text(
                                user.socialLink?.isNotEmpty == true
                                    ? user.socialLink!
                                    : _l.profileNotSet,
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
                              label: _l.profileChangePassword,
                              onTap: () => _changePassword(ctx),
                              isLast: true,
                            ),
                          ]),
                          // ── 공개 설정 ──
                          _settingsGroup(_l.profilePrivacySection, [
                            _groupSwitchTile(
                              icon: Icons.badge_rounded,
                              label: _l.profileNicknamePublic,
                              subtitle: _l.profileNicknamePublicDesc,
                              value: user.isUsernamePublic,
                              onChanged: (v) => state.updatePrivacySettings(
                                isUsernamePublic: v,
                              ),
                            ),
                            _groupSwitchTile(
                              icon: Icons.link_rounded,
                              label: _l.profileSnsLinkPublic,
                              subtitle: _l.profileSnsPublicDesc,
                              value: user.isSnsPublic,
                              onChanged: (v) =>
                                  state.updatePrivacySettings(isSnsPublic: v),
                              isLast: true,
                            ),
                          ]),
                          // ── 알림 ──
                          _settingsGroup(_l.profileNotificationSection, [
                            _groupSwitchTile(
                              icon: Icons.notifications_active_rounded,
                              label: _l.profileNearbyNotification,
                              subtitle: _l.profileNearbyNotificationDesc,
                              value: _notifyNearby,
                              onChanged: _setNotifyNearby,
                            ),
                            _groupSwitchTile(
                              icon: Icons.wb_sunny_rounded,
                              label: _l.settingsNotifyDaily,
                              subtitle: _l.settingsNotifyDailyDesc,
                              value: _notifyDaily,
                              onChanged: _setNotifyDaily,
                              isLast: true,
                            ),
                          ]),
                          // ── 화면 ──
                          _settingsGroup(_l.profileDisplaySection, [
                            _groupTile(
                              icon: Icons.brightness_6_rounded,
                              label: _l.profileDisplayMode,
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
                          _settingsGroup(_l.profileAppInfoSection, [
                            _groupTile(
                              icon: Icons.info_outline_rounded,
                              label: _l.profileVersion,
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
                              label: _l.profileCountry,
                              trailing: Text(
                                '${user.countryFlag} ${CountryL10n.localizedName(user.country, _lc)}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            _groupTile(
                              icon: Icons.language_rounded,
                              label: _l.settingsLanguage,
                              trailing: Text(
                                LanguageConfig.getLanguageName(_lc),
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                              onTap: () => _showLanguagePicker(ctx, state),
                              isLast: true,
                            ),
                          ]),
                          // ── 계정 관리 ──
                          _settingsGroup(_l.profileAccountManageSection, [
                            _groupTile(
                              icon: Icons.logout_rounded,
                              label: _l.logout,
                              iconColor: AppColors.textSecondary,
                              labelColor: AppColors.textSecondary,
                              onTap: () => _confirmLogout(ctx),
                            ),
                            _groupTile(
                              icon: Icons.delete_forever_rounded,
                              label: _l.deleteAccount,
                              iconColor: AppColors.error,
                              labelColor: AppColors.error,
                              onTap: () => _confirmDeleteAccount(ctx),
                              isLast: true,
                            ),
                          ]),
                            ],
                          ),
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
    final _al = AppL10n.of(user.languageCode);
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
                    // 일일 스트릭 뱃지 (연속 접속 일수 > 0 일 때만 표시)
                    const SizedBox(width: 8),
                    const StreakBadge(compact: true),
                  ],
                ),
                const SizedBox(height: 6),
                // 국가 + 명성 칭호 (A방향)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${user.countryFlag} ${CountryL10n.localizedName(user.country, user.languageCode)}',
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
                      user.activityScore.reputationTitleL(user.languageCode),
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
        _al.profileTitle,
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
    final _fsl = AppL10n.of(user.languageCode);
    final score = user.activityScore;
    // 나라 수: 받은 편지 발송 국가
    final countrySet = state.inbox.map((l) => l.senderCountry).toSet();
    // Build 181: 4-stat 카드 → 한 줄 compact inline. padding 14 제거,
    // container border 얇게, 이모지·수치 nowrap. 수직 공간 ~50px 회수.
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.textMuted.withValues(alpha: 0.12),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat4Inline('📬', '${score.sentCount}', _fsl.profileSentLetters),
          _stat4Inline('📥', '${score.receivedCount}', _fsl.profileReceivedLetters),
          _stat4Inline('🌍', '${countrySet.length}', _fsl.profileVisitedCountries),
          _stat4Inline('👥', '${user.followerIds.length}', _fsl.profileFollowers),
        ],
      ),
    );
  }

  /// Build 181: 4 stats 인라인 셀 — emoji + 값 + tiny label.
  Widget _stat4Inline(String emoji, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppText.small.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppText.caption.copyWith(
            color: AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── ② 구독 카드 + 오늘 발송 잔여 카드 (B+C) ─────────────────────────────────
  Widget _buildQuickCardsRow(
    BuildContext ctx,
    AppState state,
    UserProfile user,
    PurchaseService purchase,
  ) {
    final _ql = AppL10n.of(user.languageCode);
    final isBrand = purchase.isBrand || user.isBrand;
    final isPremium = isBrand || purchase.isPremium || user.isPremium;
    final planName = isBrand
        ? '🏷️ Brand'
        : isPremium
        ? '👑 Premium'
        : '⭐ Free';
    final planPrice = isBrand
        ? '₩99,000/mo'
        : isPremium
        ? '₩4,900/mo'
        : _ql.profileFree;
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
                          _ql.profileSubscriptionPlan,
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
                          _ql.profileUpgrade,
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
                    _ql.profileTodaySent,
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
                    _ql.profileResetMidnight,
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

  // ── ②-2 게임 레벨 바 — Free · Premium 전용 ───────────────────────────────
  //
  // Brand 계정은 `levelLabel` 이 "👑 공식 발송인" 으로 고정되고 currentLevel 이
  // 0 이라 진행 바 대신 단순 배지로 렌더한다. 내부 XP 필드는 누적되고 있으니
  // 계정 등급이 다시 Free 로 바뀌면 바로 정상 표시.
  Widget _buildXpLevelCard(BuildContext ctx, AppState state) {
    final user = state.currentUser;
    final l = AppL10n.of(user.languageCode);
    if (user.isBrand) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            const Text('👑', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                state.levelLabel,
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final level = state.currentLevel;
    final xp = state.currentXp;
    final progress = state.levelProgress;
    final remaining = state.xpToNextLevel;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.teal.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  state.levelLabel,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              // Build 155: 내 레벨/컴패니언 공유 버튼 — 파워 유저가 SNS 에
              // 자신의 진척을 공유해 신규 유저 유입 (바이럴 루프).
              InkWell(
                onTap: () => _shareMyLevel(ctx, state),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  child: const Icon(
                    Icons.ios_share_rounded,
                    size: 16,
                    color: AppColors.teal,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l.xpLevelBadge(level),
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.bgSurface,
              valueColor: const AlwaysStoppedAnimation(AppColors.teal),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            remaining == null
                ? l.xpLevelMaxed(xp)
                : l.xpLevelNextIn(xp, remaining),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          // 🎯 현재 레벨의 줍기 반경 보너스 표시 (Level 2 부터 +10m 단위)
          Row(
            children: [
              const Icon(
                Icons.near_me_rounded,
                size: 13,
                color: AppColors.teal,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  l.xpPickupBonusDesc(
                    state.pickupRadiusMeters.toInt(),
                    (state.currentLevel - 1).clamp(0, 49) * 10,
                  ),
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          // 🪙 Level 50 도달 시 포인트 적립 (추후 구독 결제 크레딧용)
          if (state.hasMaxLevel) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.xpPointsLabel(state.userPoints),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    l.xpPointsHint,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          // 🏆 전체 10 tier 마일스톤 보기 — 바텀시트로 레벨 1–50 구간 시각화
          InkWell(
            onTap: () => _showLevelMilestones(ctx, level, xp),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.teal.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    l.xpMilestonesSheetOpen,
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.teal,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 레벨 1–50 구간 전체 마일스톤 바텀시트. 10 tier (5 레벨 단위) 를
  /// 세로 리스트로 나열하고 현재 레벨이 속한 tier 는 골드 강조.
  void _showLevelMilestones(BuildContext ctx, int currentLevel, int currentXp) {
    final l = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    // 10 tiers — 5 레벨 간격. (level floor, emoji + label key)
    const tiers = [
      (1, '🏠'),
      (5, '🏡'),
      (10, '📬'),
      (15, '📮'),
      (20, '🏢'),
      (25, '🏬'),
      (30, '🏙'),
      (35, '🛰'),
      (40, '🌍'),
      (45, '👑'),
    ];

    showModalBottomSheet(
      context: ctx,
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
                    const Text('🏆', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.xpMilestonesTitle,
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
                const SizedBox(height: 6),
                Text(
                  l.xpMilestonesSubtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: tiers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final (floor, emoji) = tiers[i];
                      final nextFloor = i + 1 < tiers.length ? tiers[i + 1].$1 : 51;
                      final isCurrent =
                          currentLevel >= floor && currentLevel < nextFloor;
                      final isPassed = currentLevel >= nextFloor;
                      final xpReq = UserProgress.xpThresholdForLevel(floor == 0 ? 1 : floor);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.gold.withValues(alpha: 0.12)
                              : AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCurrent
                                ? AppColors.gold.withValues(alpha: 0.6)
                                : const Color(0xFF1F2D44),
                            width: isCurrent ? 1.3 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Opacity(
                              opacity: isPassed ? 0.55 : 1.0,
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.xpMilestoneTierLabel(floor == 0 ? 1 : floor, nextFloor - 1),
                                    style: TextStyle(
                                      color: isCurrent
                                          ? AppColors.gold
                                          : isPassed
                                              ? AppColors.textMuted
                                              : AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    xpLevelLabel(floor == 0 ? 1 : floor),
                                    style: TextStyle(
                                      color: isCurrent
                                          ? AppColors.gold.withValues(alpha: 0.85)
                                          : isPassed
                                              ? AppColors.textMuted
                                              : AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l.xpMilestoneXpReq(xpReq),
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l.xpMilestoneCurrent,
                                  style: const TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              )
                            else if (isPassed)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.teal,
                                size: 18,
                              )
                            else
                              Icon(
                                Icons.lock_outline_rounded,
                                color: AppColors.textMuted.withValues(alpha: 0.5),
                                size: 16,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l.xpMilestonesFootnote(currentXp),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
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

  // ── ③ 타워 등급 + 프로그레스바 (A+B) ─────────────────────────────────────
  Widget _buildTowerProgressCard(BuildContext ctx, UserProfile user) {
    final _tl = AppL10n.of(user.languageCode);
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
                      'TOWER RANK',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tier.labelL(user.languageCode),
                      style: TextStyle(
                        color: tierClr,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      score.reputationTitleL(user.languageCode),
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
                    _tl.unitPts,
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
                isMax ? '🏆 ${_tl.towerTopTierReached}' : tier.nextGoalL(user.languageCode),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              if (!isMax)
                Text(
                  _tl.towerPtsRemaining(ptsLeft.toStringAsFixed(0)),
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

/// Build 183: 프로필 하단 "설정" 전체 섹션을 접었다 펼 수 있는 버튼 + 컨테이너.
/// 기본은 접힘 — 프로필 스캔을 가볍게. 탭하면 자식들이 펼쳐진다.
class _SettingsCollapseButton extends StatefulWidget {
  final String label;
  final String sublabel;
  final List<Widget> children;

  const _SettingsCollapseButton({
    required this.label,
    required this.sublabel,
    required this.children,
  });

  @override
  State<_SettingsCollapseButton> createState() =>
      _SettingsCollapseButtonState();
}

class _SettingsCollapseButtonState extends State<_SettingsCollapseButton> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14,
              ),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _expanded
                      ? AppColors.gold.withValues(alpha: 0.5)
                      : AppColors.textMuted.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.settings_rounded,
                    size: 20,
                    color: _expanded
                        ? AppColors.gold
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: TextStyle(
                            color: _expanded
                                ? AppColors.gold
                                : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.sublabel,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _expanded
                          ? AppColors.gold
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(children: widget.children),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 240),
        ),
      ],
    );
  }
}

class _FollowListContent extends StatelessWidget {
  final String title;
  final String emptyMsg;
  final List<String> userIds;
  final Map<String, dynamic> sessions;

  const _FollowListContent({
    required this.title,
    required this.emptyMsg,
    required this.userIds,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
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
              emptyMsg,
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
