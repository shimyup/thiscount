import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../models/user_profile.dart';
import '../../../state/app_state.dart';
import '../../../core/config/app_keys.dart';
import '../../../core/config/app_links.dart';
import '../../../widgets/shared_profile_dialogs.dart';
import '../../../core/localization/country_names.dart';
import '../../../core/localization/language_config.dart';
import '../premium/premium_screen.dart';
import '../admin/admin_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool embedded;

  const SettingsScreen({super.key, this.embedded = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifyNearby = true;
  bool _notifyDaily = false;
  PushMode _pushMode = PushMode.standard;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = await NotificationService.loadPushMode();
    setState(() {
      _notifyNearby = prefs.getBool('notify_nearby') ?? true;
      _notifyDaily = prefs.getBool('notify_daily_letter') ?? false;
      _pushMode = mode;
      _loading = false;
    });
  }

  Future<void> _setPushMode(PushMode mode) async {
    await NotificationService.setPushMode(mode);
    setState(() => _pushMode = mode);
    // Quiet/Standard로 전환했는데 daily가 꺼져 있으면 매일 리마인더 자동 해제
    if (mode != PushMode.full && !_notifyDaily) {
      await NotificationService.cancelDailyLetterReminder();
    }
    // 현재 daily 리마인더가 켜져 있다면 새 모드 기준으로 재평가해 재예약
    if (_notifyDaily) {
      final lang = context.read<AppState>().currentUser.languageCode;
      await NotificationService.scheduleDailyLetterReminder(langCode: lang);
    }
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

  // ── SNS 링크 수정 ──────────────────────────────────────────────────────────
  void _editSnsLink(BuildContext ctx, AppState state) {
    final l = AppL10n.of(state.currentUser.languageCode);
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
          l.settingsSnsLink,
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
              l.settingsCancel,
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
              l.settingsSave,
              style: const TextStyle(color: AppColors.teal),
            ),
          ),
        ],
      ),
    );
  }

  // ── 비밀번호 변경 ──────────────────────────────────────────────────────────
  void _changePassword(BuildContext ctx) {
    final state = ctx.read<AppState>();
    final l = AppL10n.of(state.currentUser.languageCode);
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l.settingsChangePassword,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pwField(oldCtrl, l.settingsCurrentPw),
            const SizedBox(height: 12),
            _pwField(newCtrl, l.settingsNewPw),
            const SizedBox(height: 12),
            _pwField(confirmCtrl, l.settingsNewPwConfirm),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l.settingsCancel,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (newCtrl.text.length < 6) {
                _showSnack(ctx, l.settingsPwMin6);
                return;
              }
              if (newCtrl.text != confirmCtrl.text) {
                _showSnack(ctx, l.settingsPwMismatch);
                return;
              }
              final user = await AuthService.getCurrentUser();
              if (user == null) return;
              final err = await AuthService.login(
                username: user['username'] ?? '',
                password: oldCtrl.text,
                langCode: state.currentUser.languageCode,
              );
              if (err != null) {
                if (ctx.mounted) _showSnack(ctx, l.settingsPwError);
                return;
              }
              await AuthService.updatePassword(newCtrl.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                _showSnack(ctx, l.settingsPwChanged);
              }
            },
            child: Text(
              l.settingsSave,
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

  Future<void> _showThemeModeSelector(BuildContext ctx, AppState state, AppL10n l) async {
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
                    l.settingsThemeSelect,
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
                    l.settingsThemeAuto,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    l.settingsThemeAutoDesc,
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
                    l.settingsThemeLight,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    l.settingsThemeLightDesc,
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
                    l.settingsThemeDark,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    l.settingsThemeDarkDesc,
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

  // ── 로그아웃 ───────────────────────────────────────────────────────────────
  void _confirmLogout(BuildContext ctx) {
    final l = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l.settingsLogout,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l.settingsLogoutConfirm,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l.settingsCancel,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              // Firebase 세션이 살아있는 동안 마지막 위치·프로필을 Firestore로
              // 한 번 더 스냅샷한다. 이래야 다른 회원의 지도에서 이 테스터의
              // 타워가 "마지막 위치"로 정확히 유지된다.
              await ctx.read<AppState>().snapshotUserForLogout();
              await AuthService.logout();
              if (ctx.mounted) {
                Navigator.of(
                  ctx,
                ).pushNamedAndRemoveUntil('/auth', (_) => false);
              }
            },
            child: Text(
              l.settingsLogout,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
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

  // ── 회원탈퇴 ───────────────────────────────────────────────────────────────
  void _confirmDeleteAccount(BuildContext ctx) {
    final state = ctx.read<AppState>();
    final l = AppL10n.of(state.currentUser.languageCode);
    final username = state.currentUser.username;
    final confirmCtrl = TextEditingController();

    showDialog(
      context: ctx,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx2, setDState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            l.settingsWithdraw,
            style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.settingsWithdrawConfirm,
                style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 16),
              // 경고 박스
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.settingsWithdrawItemsHeader, style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(l.settingsWithdrawItemsList, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 유저명 입력 확인
              Text(
                l.settingsWithdrawTypeUsernameToConfirm(username),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmCtrl,
                onChanged: (_) => setDState(() {}),
                decoration: InputDecoration(
                  hintText: username,
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.bgSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.bgSurface),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.bgSurface),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text(
                l.settingsCancel,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: confirmCtrl.text.trim() == username
                  ? () async {
                      Navigator.pop(dCtx);
                      await AuthService.deleteAccount();
                      if (ctx.mounted) {
                        Navigator.of(ctx).pushNamedAndRemoveUntil('/auth', (_) => false);
                      }
                    }
                  : null,
              child: Text(
                l.settingsWithdraw,
                style: TextStyle(
                  color: confirmCtrl.text.trim() == username
                      ? AppColors.error
                      : AppColors.textMuted,
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
    // 필요한 필드만 구독 → 불필요한 rebuild 방지
    final user = context.select<AppState, UserProfile>((s) => s.currentUser);
    final themeMode = context.select<AppState, DisplayThemeMode>(
      (s) => s.displayThemeMode,
    );
    final l = AppL10n.of(user.languageCode);
    final themeLabel = switch (themeMode) {
      DisplayThemeMode.auto => l.settingsThemeAuto,
      DisplayThemeMode.light => l.settingsThemeLight,
      DisplayThemeMode.dark => l.settingsThemeDark,
    };
    return Builder(
      builder: (ctx) {
        final state = context.read<AppState>();

        return Scaffold(
          backgroundColor: AppTimeColors.of(ctx).bgDeep,
          appBar: AppBar(
            backgroundColor: AppTimeColors.of(ctx).bgDeep,
            elevation: 0,
            automaticallyImplyLeading: !widget.embedded,
            leading: widget.embedded
                ? null
                : IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
            title: Text(
              widget.embedded ? l.profile : l.settingsTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          body: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.teal),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    // ── 프리미엄 ─────────────────────────────────────────────
                    _sectionHeader(l.settingsSubscription),
                    Consumer<PurchaseService>(
                      builder: (context, purchase, _) {
                        final isPremium = purchase.isPremium || user.isPremium;
                        final isBrand = purchase.isBrand || user.isBrand;
                        return _tile(
                          iconWidget: Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            child: Text(
                              isBrand ? '🏷️' : (isPremium ? '👑' : '⭐'),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          label: isBrand
                              ? l.settingsBrandActive
                              : isPremium
                              ? l.settingsPremiumActive
                              : l.settingsPremiumUpgrade,
                          subtitle: isBrand
                              ? l.settingsBrandDesc
                              : isPremium
                              ? l.settingsPremiumDesc
                              : l.settingsFreeDesc,
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          onTap: () => Navigator.push(
                            ctx,
                            MaterialPageRoute(builder: (_) => PremiumScreen()),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    // ── 계정 ────────────────────────────────────────────────
                    _sectionHeader(l.settingsAccount),
                    _tile(
                      icon: Icons.person_rounded,
                      label: l.settingsNickname,
                      trailing: Text(
                        user.username,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      onTap: () => _editUsername(ctx, state),
                    ),
                    _tile(
                      icon: Icons.link_rounded,
                      label: l.settingsSnsLink,
                      trailing: Text(
                        user.socialLink?.isNotEmpty == true
                            ? user.socialLink!
                            : l.settingsNotSet,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      onTap: () => _editSnsLink(ctx, state),
                    ),
                    _tile(
                      icon: Icons.lock_outline_rounded,
                      label: l.settingsChangePassword,
                      onTap: () => _changePassword(ctx),
                    ),
                    _tile(
                      icon: Icons.verified_user_rounded,
                      label: l.authVerifyMethodTitle,
                      trailing: Text(
                        state.currentUser.verifyMethod == 'phone' ? 'SMS' : 'Email',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      onTap: () => _showVerifyMethodPicker(ctx, state, l),
                    ),

                    const SizedBox(height: 8),
                    // ── 알림 ────────────────────────────────────────────────
                    _sectionHeader(l.settingsNotifications),
                    _buildPushModeRow(l),
                    _switchTile(
                      icon: Icons.notifications_active_rounded,
                      label: l.settingsNotifyNearby,
                      subtitle: l.settingsNotifyNearbyDesc,
                      value: _notifyNearby,
                      onChanged: _setNotifyNearby,
                    ),
                    _switchTile(
                      icon: Icons.wb_sunny_rounded,
                      label: l.settingsNotifyDaily,
                      subtitle: l.settingsNotifyDailyDesc,
                      value: _notifyDaily,
                      onChanged: _setNotifyDaily,
                    ),

                    const SizedBox(height: 8),
                    // ── 화면 ────────────────────────────────────────────────
                    _sectionHeader(l.settingsDisplay),
                    _tile(
                      icon: Icons.brightness_6_rounded,
                      label: l.settingsDisplayMode,
                      trailing: Text(
                        themeLabel,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      onTap: () => _showThemeModeSelector(ctx, state, l),
                    ),

                    const SizedBox(height: 8),
                    // ── 앱 정보 ─────────────────────────────────────────────
                    _sectionHeader(l.settingsAppInfo),
                    _tile(
                      icon: Icons.info_outline_rounded,
                      label: l.settingsVersion,
                      trailing: const Text(
                        '1.0.0',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _tile(
                      icon: Icons.public_rounded,
                      label: l.settingsCountry,
                      trailing: Text(
                        '${user.countryFlag} ${CountryL10n.localizedName(user.country, user.languageCode)}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _tile(
                      icon: Icons.language_rounded,
                      label: l.settingsLanguage,
                      trailing: Text(
                        LanguageConfig.getLanguageName(user.languageCode),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      onTap: () => _showLanguagePicker(context, state),
                    ),
                    _tile(
                      icon: Icons.shield_outlined,
                      label: l.settingsPrivacy,
                      onTap: () async {
                        // 사용자 나라에 맞는 언어 버전 오픈
                        final url = AppLinks.privacyPolicyForCountry(
                          user.country,
                        );
                        final uri = Uri.parse(url);
                        try {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.inAppBrowserView,
                          );
                        } catch (_) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                    _tile(
                      icon: Icons.description_outlined,
                      label: l.settingsTerms,
                      onTap: () async {
                        final url = AppLinks.termsForCountry(user.country);
                        final uri = Uri.parse(url);
                        try {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.inAppBrowserView,
                          );
                        } catch (_) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 8),
                    // ── 고객 지원 ───────────────────────────────────────────
                    _sectionHeader(l.settingsSupport),
                    _tile(
                      icon: Icons.help_outline_rounded,
                      label: l.settingsContactUs,
                      subtitle: l.settingsContactUsDesc,
                      onTap: () async {
                        // 이메일 본문/제목은 bilingual 로 유지 (support 팀이 한국어)
                        final uri = Uri(
                          scheme: 'mailto',
                          path: 'support@airony.xyz',
                          queryParameters: {
                            'subject': '[Thiscount] Support / 문의',
                            'body': 'ID / 아이디: ${user.username}\nEmail / 이메일: ${user.email ?? "N/A"}\n\nMessage / 문의 내용:\n',
                          },
                        );
                        try {
                          await launchUrl(uri);
                        } catch (_) {}
                      },
                    ),
                    Consumer<PurchaseService>(
                      builder: (ctx2, purchase, _) {
                        final isPremium = purchase.isPremium || user.isPremium;
                        if (!isPremium) return const SizedBox.shrink();
                        return _tile(
                          icon: Icons.subscriptions_outlined,
                          label: l.settingsManageSubscription,
                          subtitle: l.settingsManageSubscriptionDesc,
                          onTap: () async {
                            // iOS: App Store 구독 관리 / Android: Play Store
                            const iosUrl = 'https://apps.apple.com/account/subscriptions';
                            const androidUrl = 'https://play.google.com/store/account/subscriptions';
                            final url = Uri.parse(
                              Theme.of(ctx2).platform == TargetPlatform.iOS ? iosUrl : androidUrl,
                            );
                            try {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            } catch (_) {}
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 8),
                    // ── 데이터 및 개인정보 ──────────────────────────────────
                    _sectionHeader(l.settingsDataPrivacy),
                    _tile(
                      icon: Icons.policy_outlined,
                      label: l.settingsContentPolicy,
                      onTap: () => _showContentPolicyDialog(ctx, l),
                    ),
                    _tile(
                      icon: Icons.groups_outlined,
                      label: l.settingsCommunityGuidelines,
                      onTap: () => _showCommunityGuidelinesDialog(ctx, l),
                    ),
                    _tile(
                      icon: Icons.download_outlined,
                      label: l.settingsRequestData,
                      subtitle: l.settingsRequestDataDesc,
                      onTap: () async {
                        final uri = Uri(
                          scheme: 'mailto',
                          path: 'ceo@airony.xyz',
                          queryParameters: {
                            'subject': 'Data Request - Thiscount',
                            'body': 'I would like to request a copy of my personal data.\n\nUsername: ${user.username}\nEmail: ${user.email ?? "N/A"}',
                          },
                        );
                        try {
                          await launchUrl(uri);
                        } catch (_) {}
                      },
                    ),

                    const SizedBox(height: 8),
                    // ── 계정 관리 ────────────────────────────────────────────
                    _sectionHeader(l.settingsAccountManagement),
                    _tile(
                      icon: Icons.logout_rounded,
                      label: l.settingsLogout,
                      color: AppColors.textSecondary,
                      onTap: () => _confirmLogout(ctx),
                    ),
                    _tile(
                      icon: Icons.delete_forever_rounded,
                      label: l.settingsWithdraw,
                      color: AppColors.error,
                      onTap: () => _confirmDeleteAccount(ctx),
                    ),

                    // ── 관리자 패널 (DEBUG + 테스트 이메일 · 또는 BETA_ADMIN_EMAIL) ──
                    if ((kDebugMode &&
                            user.email?.toLowerCase() ==
                                DebugConstants.testBrandEmail) ||
                        BetaConstants.isAdmin(user.email)) ...[
                      const SizedBox(height: 8),
                      _sectionHeader('🔐 ${l.settingsAdmin}'),
                      _tile(
                        iconWidget: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '⚙️',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        label: l.settingsAdminPanel,
                        subtitle: 'Admin Panel',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            l.labelAdmin,
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        onTap: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) => const AdminScreen(),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
        );
      },
    );
  }

  // ── 인증 수단 변경 ──────────────────────────────────────────────────────
  void _showVerifyMethodPicker(BuildContext ctx, AppState state, AppL10n l) {
    final current = state.currentUser.verifyMethod;
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l.authVerifyMethodTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.authVerifyMethodDesc,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            _verifyOption(ctx, state, 'email', 'Email', Icons.email_rounded, current == 'email'),
            const SizedBox(height: 8),
            _verifyOption(ctx, state, 'phone', 'SMS', Icons.phone_rounded, current == 'phone'),
          ],
        ),
      ),
    );
  }

  Widget _verifyOption(BuildContext ctx, AppState state, String method, String label, IconData icon, bool selected) {
    return GestureDetector(
      onTap: () async {
        await AuthService.updateProfile(verifyMethod: method);
        state.updateVerifyMethod(method);
        if (ctx.mounted) Navigator.pop(ctx);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.teal.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.teal
                : AppColors.textMuted.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.teal : AppColors.textMuted, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.teal : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 20),
          ],
        ),
      ),
    );
  }

  // ── 콘텐츠 열람 정책 다이얼로그 ──────────────────────────────────────────
  void _showContentPolicyDialog(BuildContext ctx, AppL10n l) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.policy_outlined, color: AppColors.teal, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l.contentPolicyTitle,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 17),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            l.contentPolicyBody,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l.authClose,
              style: const TextStyle(color: AppColors.teal),
            ),
          ),
        ],
      ),
    );
  }

  // ── 커뮤니티 가이드라인 다이얼로그 ────────────────────────────────────────
  void _showCommunityGuidelinesDialog(BuildContext ctx, AppL10n l) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.groups_outlined, color: AppColors.gold, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l.communityGuidelinesTitle,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 17),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            l.communityGuidelinesBody,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l.authClose,
              style: const TextStyle(color: AppColors.teal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPushModeRow(AppL10n l) {
    final modes = [
      (mode: PushMode.quiet, emoji: '🔕', label: l.pushModeQuiet),
      (mode: PushMode.standard, emoji: '🛎', label: l.pushModeStandard),
      (mode: PushMode.full, emoji: '📣', label: l.pushModeFull),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.pushModeLabel,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (int i = 0; i < modes.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: InkWell(
                    onTap: () => _setPushMode(modes[i].mode),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _pushMode == modes[i].mode
                            ? AppColors.teal.withValues(alpha: 0.15)
                            : AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _pushMode == modes[i].mode
                              ? AppColors.teal
                              : AppColors.textMuted.withValues(alpha: 0.3),
                          width: _pushMode == modes[i].mode ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(modes[i].emoji,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(
                            modes[i].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _pushMode == modes[i].mode
                                  ? AppColors.teal
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _pushMode == PushMode.quiet
                ? l.pushModeQuietDesc
                : _pushMode == PushMode.standard
                    ? l.pushModeStandardDesc
                    : l.pushModeFullDesc,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _tile({
    IconData? icon,
    Widget? iconWidget,
    required String label,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? color,
  }) {
    return ListTile(
      leading:
          iconWidget ??
          (icon != null
              ? Icon(icon, color: color ?? AppColors.textSecondary, size: 22)
              : null),
      title: Text(
        label,
        style: TextStyle(color: color ?? AppColors.textPrimary, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            )
          : null,
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
}
