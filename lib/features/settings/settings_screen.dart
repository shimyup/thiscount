import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
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
    // Build 421 (sim-fresh P2): OS 권한 거부 시 토글이 ON 으로 남던 오안내 수정 —
    //   profile_screen 과 동일하게 requestPermissions 결과를 토글/저장에 반영.
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      final granted = await NotificationService.requestPermissions();
      await prefs.setBool('notify_daily_letter', granted);
      if (!mounted) return;
      setState(() => _notifyDaily = granted);
      if (!granted) return;
      final lang = context.read<AppState>().currentUser.languageCode;
      await NotificationService.scheduleDailyLetterReminder(langCode: lang);
    } else {
      await prefs.setBool('notify_daily_letter', false);
      if (mounted) setState(() => _notifyDaily = false);
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
    ).then((_) => ctrl.dispose());
  }

  // ── 비밀번호 변경 ──────────────────────────────────────────────────────────
  void _changePassword(BuildContext ctx) {
    final state = ctx.read<AppState>();
    final l = AppL10n.of(state.currentUser.languageCode);
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    // Build 423 (sim-crosscut P2): 다이얼로그 종료 시 3 컨트롤러 해제(매 호출 누수).
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
              // Build 290 (P2): signUp 정규식 (8-20자 + 영문+숫자) 과 정렬.
              // 이전엔 6자 min 만 검사 → 가입시 8자 강제와 불일치 → 비밀번호
              // 변경 후 다음 로그인 시 형식 거부되는 회귀 발생.
              final pwErr = AuthService.validatePassword(
                newCtrl.text,
                langCode: state.currentUser.languageCode,
              );
              if (pwErr != null) {
                _showSnack(ctx, pwErr);
                return;
              }
              if (newCtrl.text != confirmCtrl.text) {
                _showSnack(ctx, l.settingsPwMismatch);
                return;
              }
              final user = await AuthService.getCurrentUser();
              if (user == null) return;
              // Build 395 (PR-HH4 audit D18): verifyCurrentPassword (counter
              //   미증분) — 이전 AuthService.login 호출 시 _recordLoginFailure
              //   카운트 누적 → 본인 4회 실수 + 다음 1회 login = self-lockout
              //   회귀.
              final ok = await AuthService.verifyCurrentPassword(oldCtrl.text);
              if (!ok) {
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
    ).then((_) {
      oldCtrl.dispose();
      newCtrl.dispose();
      confirmCtrl.dispose();
    });
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

  Future<void> _showThemeModeSelector(
    BuildContext ctx,
    AppState state,
    AppL10n l,
  ) async {
    await showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 16),
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
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
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
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
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
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
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

  // Build 385 (PR-FF4 audit C7): GDPR Art.20 — 사용자 데이터 portability export.
  // currentUser + inbox + sent + consents 를 JSON 으로 share intent.
  // share_plus 사용 — iOS/Android 양쪽 system share sheet 노출.
  Future<void> _exportUserData(BuildContext ctx) async {
    final state = ctx.read<AppState>();
    final l = AppL10n.of(state.currentUser.languageCode);
    try {
      final u = state.currentUser;
      // Build 399 (PR-II1 audit B11): GDPR Art.20 "all personal data" 요건 —
      //   누락된 14 필드 추가 + version 동적.
      //   APP_VERSION 은 빌드 스크립트가 dart-define 으로 주입 권장
      //   (`--dart-define=APP_VERSION=1.0.0+399`). 미주입 시 'dev' 표시 —
      //   stale 하드코딩 (이전 '385') 보다 정직.
      const appVersion = String.fromEnvironment(
        'APP_VERSION',
        defaultValue: 'dev',
      );
      final prefs = await SharedPreferences.getInstance();
      // Build 414 (sim P2): 동의 타임스탬프는 Build 286 부터 FlutterSecureStorage
      //   에 저장(auth_screen._consentStore)되는데, export 는 SharedPreferences
      //   에서 (게다가 2건은 잘못된 키로) 읽어 GDPR Art.20 export 가 동의 항목을
      //   항상 null 로 내보내고 있었다. 동일 store/키로 정정.
      const consentStore = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );
      final consents = <String, String?>{
        'consent_terms_ts': await consentStore.read(key: 'consent_terms_ts'),
        'consent_privacy_ts':
            await consentStore.read(key: 'consent_privacy_ts'),
        'consent_marketing_ts':
            await consentStore.read(key: 'consent_marketing_ts'),
        'consent_thirdparty_ts':
            await consentStore.read(key: 'consent_third_party_sharing_ts'),
        'consent_age14_ts':
            await consentStore.read(key: 'consent_age_above14_ts'),
      };
      final data = <String, dynamic>{
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'app': 'Thiscount',
        'version': appVersion,
        'user': {
          'id': u.id,
          'username': u.username,
          'country': u.country,
          'countryFlag': u.countryFlag,
          'languageCode': u.languageCode,
          'email': u.email,
          'phoneNumber': u.phoneNumber,
          'isPremium': u.isPremium,
          'isBrand': u.isBrand,
          'isMapPublic': u.isMapPublic,
          'isUsernamePublic': u.isUsernamePublic,
          'joinedAt': u.joinedAt.toUtc().toIso8601String(),
          'latitude': u.latitude,
          'longitude': u.longitude,
          'lastKnownLatitude': prefs.getDouble('lkLat_v1'),
          'lastKnownLongitude': prefs.getDouble('lkLng_v1'),
        },
        'consents': consents,
        'activityScore': u.activityScore.toJson(),
        'trial': {
          'welcomeTrialClaimedAt': prefs.getString('welcomeTrialClaimedAt'),
        },
        'invite': {
          'inviteCode': prefs.getString('inviteCode'),
          'inviteAppliedCode': prefs.getString('inviteAppliedCode'),
          'inviteRewardCredits': prefs.getInt('inviteRewardCredits'),
        },
        'streak': {
          'current': prefs.getInt('streak_current'),
          'longest': prefs.getInt('streak_longest'),
          'lastCheckin': prefs.getString('streak_last_checkin'),
        },
        'brandExtra': {
          'monthlyQuota': prefs.getInt('brandExtraMonthlyQuota'),
        },
        'exactDrop': {
          'credits': prefs.getInt('brandExactDropCredits'),
        },
        'inbox': state.inbox.map((l) => l.toJson()).toList(),
        'sent': state.sent.map((l) => l.toJson()).toList(),
      };
      final json = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/thiscount_data_$ts.json');
      await file.writeAsString(json);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Thiscount Data Export',
      );
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('${l.settingsExportFailed}: $e')),
      );
    }
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
              Divider(
                height: 1,
                color: AppColors.textMuted.withValues(alpha: 0.2),
              ),
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
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.teal,
                              size: 20,
                            )
                          : const Icon(
                              Icons.circle_outlined,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                      title: Text(
                        name,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.teal
                              : AppColors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                      onTap: () async {
                        state.updateProfile(languageCode: code);
                        // Build 421 (sim-fresh P3): 일일 리마인더가 켜져 있으면
                        //   새 언어로 재예약 — 이전엔 옛 언어 본문으로 잔존.
                        if (_notifyDaily) {
                          await NotificationService.scheduleDailyLetterReminder(
                            langCode: code,
                          );
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            l.settingsWithdraw,
            style: const TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.settingsWithdrawConfirm,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              // 경고 박스
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.settingsWithdrawItemsHeader,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.settingsWithdrawItemsList,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 유저명 입력 확인
              Text(
                l.settingsWithdrawTypeUsernameToConfirm(username),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
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
                      // Build 414 (sim200 P2): 탈퇴 전 서버 sync 타이머 정지 —
                      //   안 멈추면 삭제 직후 타이머가 user doc 을 재기록(부활)해
                      //   GDPR 삭제가 무력화됨(로그아웃과 동일 대칭).
                      ctx.read<AppState>().stopServerSync();
                      await AuthService.deleteAccount();
                      if (ctx.mounted) {
                        Navigator.of(
                          ctx,
                        ).pushNamedAndRemoveUntil('/auth', (_) => false);
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
    ).then((_) => confirmCtrl.dispose());
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
                    tooltip: l.koEn('뒤로', 'Back'),
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
                        state.currentUser.verifyMethod == 'phone'
                            ? 'SMS'
                            : 'Email',
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
                        // Build 421 (sim-fresh P3): 위치약관 타일과 동일하게 앱
                        //   언어 기준 — 나라 기준은 비-한국 거주 한국어 사용자가
                        //   영문 문서를 보던 불일치.
                        final url = AppLinks.privacyPolicyForLanguage(
                          user.languageCode,
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
                        final url =
                            AppLinks.termsForLanguage(user.languageCode);
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
                    // Build 411 (launch): 위치기반서비스 이용약관 (위치정보법
                    //   별도 게시 의무) — 개인정보처리방침/이용약관과 분리해 노출.
                    _tile(
                      icon: Icons.location_on_outlined,
                      label: l.koEn('위치기반서비스 이용약관',
                          'Location-Based Service Terms'),
                      onTap: () async {
                        final uri = Uri.parse(
                          AppLinks.locationTermsForLanguage(user.languageCode),
                        );
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
                    // Build 311: 온보딩 다시 보기 옵션 — markSeen flag 를 reset 후
                    // 라우터의 splash 흐름을 재진입시켜 인포그래픽 투어 + 온보딩
                    // 화면을 처음부터 다시 표시.
                    _tile(
                      icon: Icons.replay_circle_filled_rounded,
                      label: l.settingsReplayOnboarding,
                      subtitle: l.settingsReplayOnboardingDesc,
                      onTap: () async {
                        await AuthService.resetOnboardingFlags();
                        if (!context.mounted) return;
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/splash',
                          (r) => false,
                        );
                      },
                    ),
                    _tile(
                      icon: Icons.help_outline_rounded,
                      label: l.settingsContactUs,
                      subtitle: l.settingsContactUsDesc,
                      onTap: () async {
                        // Build 310: 지원 채널 ceo@airony.xyz 로 통일 (출시 전
                        // 1인 운영 단계 — 모든 사용자 문의 직접 수신).
                        final uri = Uri(
                          scheme: 'mailto',
                          path: 'ceo@airony.xyz',
                          queryParameters: {
                            'subject': '[Thiscount] Support / 문의',
                            'body':
                                'ID / 아이디: ${user.username}\nEmail / 이메일: ${user.email ?? "N/A"}\n\nMessage / 문의 내용:\n',
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
                        // Build 300 (MED audit): trial-only 사용자에게 Apple
                        // "Manage Subscription" 페이지가 비어있어 혼란.
                        // 실제 결제 사용자 (_nextBillingDate != null) 일 때만
                        // 노출. trial 만 활성인 경우 hide.
                        final hasPaidSubscription =
                            isPremium && purchase.nextBillingDate != null;
                        if (!hasPaidSubscription) {
                          return const SizedBox.shrink();
                        }
                        return _tile(
                          icon: Icons.subscriptions_outlined,
                          label: l.settingsManageSubscription,
                          subtitle: l.settingsManageSubscriptionDesc,
                          onTap: () async {
                            // iOS: App Store 구독 관리 / Android: Play Store
                            const iosUrl =
                                'https://apps.apple.com/account/subscriptions';
                            const androidUrl =
                                'https://play.google.com/store/account/subscriptions';
                            final url = Uri.parse(
                              Theme.of(ctx2).platform == TargetPlatform.iOS
                                  ? iosUrl
                                  : androidUrl,
                            );
                            try {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            } catch (_) {}
                          },
                        );
                      },
                    ),
                    // Build 297 (P0 audit, Apple 3.1.1): Restore Purchases 타일
                    // 을 Premium 여부와 무관하게 노출. 사용자가 재설치/기기 변경
                    // 후 entitlement 가 빠진 상태에서도 Settings 로 복구 가능.
                    Consumer<PurchaseService>(
                      builder: (ctx2, purchase, _) {
                        return _tile(
                          icon: Icons.restore_rounded,
                          label: l.settingsRestorePurchases,
                          subtitle: l.settingsRestorePurchasesDesc,
                          onTap: () async {
                            final ok = await purchase.restorePurchases();
                            if (!ctx2.mounted) return;
                            ScaffoldMessenger.of(ctx2).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? l.settingsRestorePurchasesOk
                                    : l.settingsRestorePurchasesEmpty),
                                backgroundColor: AppColors.bgCard,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
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
                          path: AppLinks.supportEmail,
                          queryParameters: {
                            'subject': 'Data Request - Thiscount',
                            'body':
                                'I would like to request a copy of my personal data.\n\nUsername: ${user.username}\nEmail: ${user.email ?? "N/A"}',
                          },
                        );
                        try {
                          await launchUrl(uri);
                        } catch (_) {}
                      },
                    ),
                    // Build 302 (HIGH privacy audit): 동의 철회 in-app 경로 안내.
                    // GDPR Art.7(3) + KISA — 사용자가 모든 (또는 일부) 동의를
                    // 철회할 수 있어야 함. 현재 모델은 all-or-nothing (회원 탈퇴)
                    // 이므로 사용자에게 명시 안내 + support 채널 제공.
                    _tile(
                      icon: Icons.rule_folder_outlined,
                      label: l.settingsWithdrawConsent,
                      subtitle: l.settingsWithdrawConsentDesc,
                      onTap: () async {
                        final uri = Uri(
                          scheme: 'mailto',
                          path: AppLinks.supportEmail,
                          queryParameters: {
                            'subject': 'Consent Withdrawal - Thiscount',
                            'body':
                                'I would like to withdraw consent for specific data processing.\n\nUsername: ${user.username}\nEmail: ${user.email ?? "N/A"}\n\nDetails:\n- [ ] Third-party sharing (Firebase / RevenueCat / Resend / Twilio / etc.)\n- [ ] Location processing\n- [ ] Marketing communications\n- [ ] Other (specify): ',
                          },
                        );
                        // Build 414 (sim100 #38): 메일 앱 없으면 launchUrl 이
                        //   조용히 실패해 데드버튼이었다. canLaunchUrl 사전체크 +
                        //   실패 시 support 이메일을 SnackBar 로 직접 노출(복사 가능).
                        bool ok = false;
                        try {
                          if (await canLaunchUrl(uri)) {
                            ok = await launchUrl(uri);
                          }
                        } catch (_) {}
                        if (!ok && ctx.mounted) {
                          await Clipboard.setData(
                            ClipboardData(text: AppLinks.supportEmail),
                          );
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${l.settingsWithdrawConsent}: ${AppLinks.supportEmail}',
                              ),
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
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
                    // Build 385 (PR-FF4 audit C7): GDPR Art.20 portability —
                    //   사용자가 자기 데이터 download. inbox / sent / 프로필 /
                    //   consents 를 JSON 으로 share intent.
                    _tile(
                      icon: Icons.download_rounded,
                      label: l.settingsExportData,
                      color: AppColors.textSecondary,
                      onTap: () => _exportUserData(ctx),
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
            _verifyOption(
              ctx,
              state,
              'email',
              'Email',
              Icons.email_rounded,
              current == 'email',
            ),
            const SizedBox(height: 8),
            _verifyOption(
              ctx,
              state,
              'phone',
              'SMS',
              Icons.phone_rounded,
              current == 'phone',
            ),
          ],
        ),
      ),
    );
  }

  Widget _verifyOption(
    BuildContext ctx,
    AppState state,
    String method,
    String label,
    IconData icon,
    bool selected,
  ) {
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
            Icon(
              icon,
              color: selected ? AppColors.teal : AppColors.textMuted,
              size: 20,
            ),
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
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.teal,
                size: 20,
              ),
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
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                ),
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
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                ),
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
      padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 8),
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
                          Text(
                            modes[i].emoji,
                            style: const TextStyle(fontSize: 18),
                          ),
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

  // Build 404 (PR-MM5): section header 시각 hierarchy 개선.
  //   - top spacing 16 → 20 (그룹 사이 호흡 ↑)
  //   - 제목 옆에 8px 짧은 teal underline → 그룹 시작 명확히 신호
  //   - 폰트 11.5 + letter-spacing 1.4 로 더 caps-look (typography polish)
  //   9 섹션 (구독/계정/알림/화면/앱정보/지원/데이터/계정관리/관리자) 모두
  //   동일 hierarchy 로 통일.
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.teal,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
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
