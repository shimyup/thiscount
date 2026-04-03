import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../models/user_profile.dart';
import '../../../state/app_state.dart';
import '../../../core/config/app_keys.dart';
import '../../../core/config/app_links.dart';
import '../../../widgets/shared_profile_dialogs.dart';
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
  bool _loading = true;

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

  Future<void> _showThemeModeSelector(BuildContext ctx, AppState state) async {
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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '화면 모드 선택',
                    style: TextStyle(
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
                  title: const Text(
                    '자동 (시간대)',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: const Text(
                    '국가 시간에 따라 낮/밤 테마 자동 변경',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
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
                  title: const Text(
                    '밝은 모드',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: const Text(
                    '항상 낮 테마로 표시',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
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
                  title: const Text(
                    '다크 모드',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: const Text(
                    '항상 밤 테마로 표시',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
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

  // ── 회원탈퇴 ───────────────────────────────────────────────────────────────
  void _confirmDeleteAccount(BuildContext ctx) {
    final l = AppL10n.of(ctx.read<AppState>().currentUser.languageCode);
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l.settingsWithdraw,
          style: const TextStyle(color: AppColors.error),
        ),
        content: Text(
          l.settingsWithdrawConfirm,
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
              await AuthService.deleteAccount();
              if (ctx.mounted) {
                Navigator.of(
                  ctx,
                ).pushNamedAndRemoveUntil('/auth', (_) => false);
              }
            },
            child: Text(
              l.settingsWithdraw,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 필요한 필드만 구독 → 불필요한 rebuild 방지
    final user = context.select<AppState, UserProfile>((s) => s.currentUser);
    final themeLabel = context.select<AppState, String>(
      (s) => s.displayThemeModeLabel,
    );
    final l = AppL10n.of(user.languageCode);
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
              widget.embedded ? '프로필' : l.settingsTitle,
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
                    _sectionHeader('구독'),
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
                              ? 'Brand 이용 중'
                              : isPremium
                              ? 'Premium 이용 중'
                              : 'Premium 업그레이드',
                          subtitle: isBrand
                              ? '인증 브랜드 계정 · 구독 관리'
                              : isPremium
                              ? '하루 30통 · 사진 첨부(20통) · 월 500통'
                              : '하루 3통 · 사진 첨부 불가 · 월 100통',
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
                      label: '닉네임',
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
                            : '미설정',
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

                    const SizedBox(height: 8),
                    // ── 알림 ────────────────────────────────────────────────
                    _sectionHeader(l.settingsNotifications),
                    _switchTile(
                      icon: Icons.notifications_active_rounded,
                      label: l.settingsNotifyNearby,
                      subtitle: '2km 이내에 편지가 도착하면 알림',
                      value: _notifyNearby,
                      onChanged: _setNotifyNearby,
                    ),

                    const SizedBox(height: 8),
                    // ── 화면 ────────────────────────────────────────────────
                    _sectionHeader('화면'),
                    _tile(
                      icon: Icons.brightness_6_rounded,
                      label: '화면 모드',
                      trailing: Text(
                        themeLabel,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      onTap: () => _showThemeModeSelector(ctx, state),
                    ),

                    const SizedBox(height: 8),
                    // ── 앱 정보 ─────────────────────────────────────────────
                    _sectionHeader('앱 정보'),
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
                      label: '나라',
                      trailing: Text(
                        '${user.countryFlag} ${user.country}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
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

                    const SizedBox(height: 8),
                    // ── 계정 관리 ────────────────────────────────────────────
                    _sectionHeader('계정 관리'),
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

                    // ── 관리자 패널 (DEBUG + 지정 테스트 계정 전용) ────────────
                    if (kDebugMode &&
                        user.email?.toLowerCase() ==
                            DebugConstants.testBrandEmail) ...[
                      const SizedBox(height: 8),
                      _sectionHeader('🔐 관리자'),
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
                        label: '관리자 패널',
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
                          child: const Text(
                            'ADMIN',
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
