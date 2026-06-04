import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/secure_location.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/sms_service.dart';
import '../../../core/localization/language_config.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/country_names.dart';
import '../../../core/config/app_links.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/email_service.dart';
import '../../../state/app_state.dart';
import '../../../core/services/purchase_service.dart';
import 'package:provider/provider.dart';

/// Returns device language code, restricted to the 14 supported languages.
String _deviceLangCode() {
  final code = ui.PlatformDispatcher.instance.locale.languageCode;
  const supported = {'ko','en','ja','zh','fr','de','es','pt','ru','tr','ar','it','hi','th'};
  return supported.contains(code) ? code : 'en';
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _selectedLang;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedLang = _deviceLangCode();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          // 배경 별빛
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _AuthBgPainter(),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                // 언어 선택 버튼
                _buildLanguageSelector(),
                const SizedBox(height: 16),
                // 앱 로고
                _buildLogo(),
                const SizedBox(height: 32),
                // 탭 바
                _buildTabBar(),
                const SizedBox(height: 8),
                // 탭 뷰
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _LoginTab(onLoginSuccess: _onAuthSuccess, langCode: _selectedLang),
                      _SignupTab(onSignupSuccess: _onAuthSuccess, langCode: _selectedLang),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    final l = AppL10n.of(_selectedLang);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Build 263: 옛 "letter.go." 워드마크 → "Thiscount" 로 정리.
          const Text(
            'Thiscount',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 0.92,
              letterSpacing: -3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.tagline,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    final langName = LanguageConfig.getLanguageName(_selectedLang);
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          onTap: _showLanguagePicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.textMuted.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language_rounded, color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 6),
                Text(
                  langName,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more_rounded, color: AppColors.textMuted, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    final languages = LanguageConfig.languageNames.entries.toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '🌐 Language',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 350,
              child: ListView.builder(
                itemCount: languages.length,
                itemBuilder: (_, i) {
                  final code = languages[i].key;
                  final name = languages[i].value;
                  final selected = code == _selectedLang;
                  return ListTile(
                    leading: selected
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 20)
                        : const Icon(Icons.circle_outlined, color: AppColors.textMuted, size: 20),
                    title: Text(
                      name,
                      style: TextStyle(
                        color: selected ? AppColors.teal : AppColors.textSecondary,
                        fontSize: 15,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                    onTap: () {
                      setState(() => _selectedLang = code);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bgSurface),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.gold,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: [
          Tab(text: AppL10n.of(_selectedLang).authTabLogin),
          Tab(text: AppL10n.of(_selectedLang).authTabSignup),
        ],
      ),
    );
  }

  Future<void> _onAuthSuccess(Map<String, String> userData) async {
    final state = context.read<AppState>();

    // 로그인 직후 현재 위치를 가져와서 setUser에 전달
    Position? pos;
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        final rawPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
          ),
        ).timeout(const Duration(seconds: 5));
        // Build 370 (PR-CC4 P0 #9): GPS spoofing 가드.
        pos = SecureLocation.guard(rawPos);
      }
    } catch (_) {}

    state.setUser(
      id: userData['id'] ?? '',
      username: userData['username'] ?? '',
      country: userData['country'] ?? '대한민국',
      countryFlag: userData['countryFlag'] ?? '🇰🇷',
      languageCode: userData['languageCode'],
      socialLink: userData['socialLink'],
      phoneNumber: userData['phoneNumber'],
      verifyMethod: userData['verifyMethod'] ?? 'email',
      latitude: pos?.latitude,
      longitude: pos?.longitude,
      // Build 414 (sim200 P1-2): cold-start(main.dart) 경로와 동일하게 Brand
      //   상태 전달. 누락 시 같은 세션 내 Brand 계정 로그인 전환 때 setUser 의
      //   isNewUser 분기가 기본 isBrand:false 로 덮어써 Brand→Free 강등됐다.
      isBrand: userData['isBrand'] == 'true',
      brandName: (userData['brandName']?.isNotEmpty == true)
          ? userData['brandName']
          : null,
    );
    // 이메일을 UserProfile에 저장 (이메일 기반 기능에 필요)
    if (userData['email']?.isNotEmpty == true) {
      state.updateProfile(email: userData['email']);
    }
    // shimyup@gmail.com → 디버그 빌드에서 자동 브랜드 계정 적용
    if (context.mounted) {
      await context.read<PurchaseService>().syncUserIdentity(
        userId: userData['id'],
        email: userData['email'],
      );
      await context.read<PurchaseService>().applyTestEmailOverride(
        userData['email'],
      );
    }
    final onboardingDone = await AuthService.isOnboardingComplete();
    if (!mounted) return;

    if (!onboardingDone) {
      Navigator.of(context).pushReplacementNamed('/onboarding');
      return;
    }

    Navigator.of(context).pushReplacementNamed('/home');
  }
}

// ── 로그인 탭 ─────────────────────────────────────────────────────────────────
class _LoginTab extends StatefulWidget {
  final Future<void> Function(Map<String, String>) onLoginSuccess;
  final String langCode;
  const _LoginTab({required this.onLoginSuccess, required this.langCode});

  @override
  State<_LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends State<_LoginTab> {
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;
  bool _rememberMe = false; // 기본 비활성 — 개인정보 보호 (사용자가 명시적으로 선택)
  String? _error;

  static const _kRememberMe = 'login_remember_me';
  static const _kSavedUsername = 'login_saved_username';
  static const _kSavedPasswordSecure = 'login_saved_pw_v2';

  // iOS Keychain / Android EncryptedSharedPreferences — 앱 업데이트 후에도 유지
  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_kRememberMe) ?? false;
    // 레거시 평문 저장분 정리
    await prefs.remove('login_saved_password');
    await prefs.remove('login_saved_password_secure');
    if (!remember) return;
    final username = prefs.getString(_kSavedUsername) ?? '';
    final password = await _secure.read(key: _kSavedPasswordSecure) ?? '';
    if (username.isNotEmpty && mounted) {
      setState(() {
        _rememberMe = true;
        _usernameCtrl.text = username;
        if (password.isNotEmpty) _passCtrl.text = password;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool(_kRememberMe, true);
      await prefs.setString(_kSavedUsername, _usernameCtrl.text.trim());
      // 비밀번호를 FlutterSecureStorage에 암호화 저장 (앱 업데이트 후에도 유지)
      await _secure.write(
        key: _kSavedPasswordSecure,
        value: _passCtrl.text,
      );
    } else {
      await prefs.remove(_kRememberMe);
      await prefs.remove(_kSavedUsername);
      await _secure.delete(key: _kSavedPasswordSecure);
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Build 423 (sim-crosscut P3): 재진입 가드 — 더블탭 시 중복 로그인/네비 차단.
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final err = await AuthService.login(
      username: _usernameCtrl.text,
      password: _passCtrl.text,
      langCode: _deviceLangCode(),
    );

    if (!mounted) return;

    if (err != null) {
      setState(() {
        _isLoading = false;
        _error = err;
      });
      return;
    }

    await _saveCredentials();

    final user = await AuthService.getCurrentUser();
    if (user != null) await widget.onLoginSuccess(user);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(widget.langCode);
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) _ErrorBanner(message: _error!),
          _InputField(
            controller: _usernameCtrl,
            label: l10n.authNicknameId,
            hint: 'Traveler_42',
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 14),
          _InputField(
            controller: _passCtrl,
            label: l10n.password,
            hint: l10n.authPasswordHint,
            icon: Icons.lock_rounded,
            obscureText: _obscurePass,
            suffixIcon: IconButton(
              // Build 423 (sim-crosscut P2): a11y — 상태 반영 tooltip.
              tooltip: _obscurePass
                  ? l10n.koEn('비밀번호 표시', 'Show password')
                  : l10n.koEn('비밀번호 숨기기', 'Hide password'),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
              icon: Icon(
                _obscurePass
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // ── 아이디/비번 기억하기 ───────────────────────────────────────────
          // Build 423 (sim-crosscut P2): a11y — 토글 역할/상태/라벨 노출.
          Semantics(
            container: true,
            checked: _rememberMe,
            label: l10n.koEn('아이디/비밀번호 기억하기', 'Remember me'),
            child: GestureDetector(
            onTap: () => setState(() => _rememberMe = !_rememberMe),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _rememberMe ? AppColors.teal : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: _rememberMe
                          ? AppColors.teal
                          : AppColors.textMuted.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: _rememberMe
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: AppColors.bgDeep,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.authRememberMe,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ),
          const SizedBox(height: 20),
          _AuthButton(
            label: l10n.login,
            emoji: '🔑',
            isLoading: _isLoading,
            onTap: _login,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: l10n.findId,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _showFindIdDialog(),
                  ),
                  const TextSpan(
                    text: '   ·   ',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  TextSpan(
                    text: l10n.resetPassword,
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _showResetPasswordDialog(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              l10n.authNewUserHint,
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ),
          // ── 디버그 전용: 빠른 로그인 ──────────────────────────────────────
          if (kDebugMode) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    '🔧 DEBUG: 빠른 테스트',
                    style: TextStyle(
                      color: Colors.purple,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        setState(() => _isLoading = true);
                        // 테스트 계정 자동 생성 or 로그인
                        const testUser = 'testuser123';
                        const testPw = 'Test1234!';
                        final taken = await AuthService.isUsernameTaken(
                          testUser,
                        );
                        if (!taken) {
                          await AuthService.signUp(
                            username: testUser,
                            password: testPw,
                            email: 'test@thiscount.io',
                            country: '대한민국',
                            countryFlag: '🇰🇷',
                            langCode: _deviceLangCode(),
                          );
                        }
                        final err = await AuthService.login(
                          username: testUser,
                          password: testPw,
                          langCode: _deviceLangCode(),
                        );
                        if (!mounted) return;
                        if (err == null) {
                          final userData = await AuthService.getCurrentUser();
                          if (userData != null && mounted) {
                            await widget.onLoginSuccess(userData);
                          }
                        }
                        if (mounted) setState(() => _isLoading = false);
                      },
                      child: const Text(
                        '테스트 계정으로 로그인',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 아이디 찾기 ─────────────────────────────────────────────────────────────
  void _showFindIdDialog() {
    final emailCtrl = TextEditingController();
    bool isLoading = false;
    final l10n = AppL10n.of(widget.langCode);

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (sCtx, setS) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            l10n.findId,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.authFindIdDesc,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: l10n.authRegisteredEmail,
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.gold),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogCtx),
              child: Text(
                l10n.authCancel,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.bgDeep,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      final email = emailCtrl.text.trim();
                      if (email.isEmpty) return;
                      setS(() => isLoading = true);

                      // 이메일로 아이디 조회
                      final idResult = await AuthService.findId(email: email, langCode: _deviceLangCode());

                      if (!mounted || !context.mounted || !dialogCtx.mounted)
                        return;

                      if (idResult['success'] != true) {
                        setS(() => isLoading = false);
                        Navigator.pop(dialogCtx);
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: AppColors.bgCard,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text(
                              l10n.authFindFailed,
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                            content: Text(
                              idResult['error'] ?? l10n.authNoAccountForEmail,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  l10n.authConfirm,
                                  style: const TextStyle(color: AppColors.textMuted),
                                ),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      final foundUsername =
                          idResult['username'] as String? ?? '';

                      // 임시 비밀번호 발급
                      final pwResult = await AuthService.resetPassword(
                        username: foundUsername,
                        email: email,
                        langCode: _deviceLangCode(),
                      );

                      // Build 297 (P0 audit): release 빌드에서 임시 비번 이메일 전송.
                      // 이전엔 화면 노출만 차단되어 사용자가 임시 비번을 받을 채널이
                      // 없어 영구 잠금.
                      bool pwEmailDelivered = false;
                      String? pwEmailError;
                      if (pwResult['success'] == true && !kDebugMode) {
                        final pw = pwResult['tempPassword'] as String?;
                        if (pw != null && pw.isNotEmpty) {
                          pwEmailError = await EmailService.sendTempPassword(
                            to: email,
                            tempPassword: pw,
                            expiresInMinutes:
                                (pwResult['expiresInMinutes'] as int?) ?? 30,
                            langCode: _deviceLangCode(),
                          );
                          pwEmailDelivered = pwEmailError == null;
                        }
                      }

                      if (!mounted || !context.mounted || !dialogCtx.mounted)
                        return;
                      Navigator.pop(dialogCtx);

                      final pwOk = pwResult['success'] == true;
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: AppColors.bgCard,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            l10n.authAccountInfo,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 아이디 표시
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.gold.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.authId,
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      foundUsername,
                                      style: const TextStyle(
                                        color: AppColors.gold,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (pwOk) ...[
                                const SizedBox(height: 10),
                                // 보안 정책: 릴리즈 빌드에서는 임시 비밀번호 평문 미노출
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.teal.withValues(
                                      alpha: 0.10,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.teal.withValues(
                                        alpha: 0.35,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.authPasswordResetDone,
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (kDebugMode)
                                        Text(
                                          pwResult['tempPassword'] as String? ??
                                              '',
                                          style: const TextStyle(
                                            color: AppColors.teal,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.0,
                                          ),
                                        )
                                      else
                                        Text(
                                          pwEmailDelivered
                                              ? l10n.authTempPasswordSentToEmail(email)
                                              : (pwEmailError ??
                                                    l10n.authTempPasswordSendFailed),
                                          style: TextStyle(
                                            color: pwEmailDelivered
                                                ? AppColors.textPrimary
                                                : AppColors.error,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      const SizedBox(height: 6),
                                      Text(
                                        l10n.authTempPasswordExpiry(pwResult['expiresInMinutes']),
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                l10n.authConfirm,
                                style: const TextStyle(color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.bgDeep,
                      ),
                    )
                  : Text(
                      l10n.authFind,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
      // Build 423 (sim-crosscut P3): 다이얼로그 종료 시 컨트롤러 해제.
    ).then((_) => emailCtrl.dispose());
  }

  void _showResetPasswordDialog() {
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final l10n = AppL10n.of(widget.langCode);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.resetPassword,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.authResetPasswordDesc,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usernameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.authNicknameId,
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
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.teal),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.authRegisteredEmailRequired,
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
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.teal),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.authCancel,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final inputEmail = emailCtrl.text.trim();
              final lang = _deviceLangCode();
              final result = await AuthService.resetPassword(
                username: usernameCtrl.text.trim(),
                email: inputEmail,
                langCode: lang,
              );
              if (!mounted) return;
              final bool ok = result['success'] == true;
              // Build 297 (P0 audit): release 빌드에서 화면 노출 차단된 임시 비번
              // 을 이메일로 전송. 이전엔 어떤 채널로도 전달되지 않아 영구 잠금.
              // Build 414 (sim P2): relay(Cloud Function) 미설정 release 에서는
              //   EmailService 가 발송 없이 null 을 반환 → 과거엔 emailDelivered=
              //   true 로 "이메일 발송됨" 거짓 안내 + 임시비번 미전달(사실상 잠금).
              //   relay 미설정이면 debug 와 동일하게 화면에 임시비번을 직접 노출
              //   (fallback) 해 사용자가 잠기지 않게 한다.
              final bool showOnScreen =
                  kDebugMode || !EmailService.isConfigured;
              bool emailDelivered = false;
              String? emailError;
              if (ok && !showOnScreen) {
                final pw = result['tempPassword'] as String?;
                if (pw != null && pw.isNotEmpty) {
                  emailError = await EmailService.sendTempPassword(
                    to: inputEmail,
                    tempPassword: pw,
                    expiresInMinutes:
                        (result['expiresInMinutes'] as int?) ?? 30,
                    langCode: lang,
                  );
                  emailDelivered = emailError == null;
                }
              }
              if (!mounted) return;
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.bgCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    ok ? l10n.authTempPasswordIssued : l10n.authFindFailed,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  content: Text(
                    ok
                        ? (showOnScreen
                              ? '${l10n.authTempPasswordLabel}: ${result['tempPassword']}\n'
                                    '${l10n.authExpiresInMinutes(result['expiresInMinutes'])}\n'
                                    '${l10n.authMustChangeAfterLogin}'
                              : (emailDelivered
                                    ? '${l10n.authTempPasswordSentToEmail(inputEmail)}\n'
                                          '${l10n.authExpiresInMinutes(result['expiresInMinutes'])}\n'
                                          '${l10n.authMustChangeAfterLogin}'
                                    : (emailError ??
                                          l10n.authTempPasswordSendFailed)))
                        : (result['error'] ?? l10n.authErrorOccurred),
                    style: TextStyle(
                      color: ok && (showOnScreen || emailDelivered)
                          ? AppColors.teal
                          : AppColors.error,
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.authConfirm),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
            child: Text(l10n.authIssue, style: const TextStyle(color: AppColors.bgDeep)),
          ),
        ],
      ),
      // Build 423 (sim-crosscut P3): 다이얼로그 종료 시 2 컨트롤러 해제.
    ).then((_) {
      usernameCtrl.dispose();
      emailCtrl.dispose();
    });
  }
}

// ── 회원가입 탭 ───────────────────────────────────────────────────────────────
class _SignupTab extends StatefulWidget {
  final Future<void> Function(Map<String, String>) onSignupSuccess;
  final String langCode;
  const _SignupTab({required this.onSignupSuccess, required this.langCode});

  @override
  State<_SignupTab> createState() => _SignupTabState();
}

/// Build 405 (PR-NN1): 회원 가입 종류.
///
/// - [general]: Free / Premium tier path. 픽업·인박스·답장 중심 UX.
/// - [brand]: Business path. 즉시 isBrand=true 로 가입, 캠페인 발송 UX.
///
/// 가입 시점에 선택하여 이후 MainScaffold 분기 (NN3) 와 가입 form 분기
/// (NN2) 의 입구가 된다. 가입 후 변경 가능 (settings 에서).
enum SignupAccountType { general, brand }

class _SignupTabState extends State<_SignupTab> {
  // Build 405 (PR-NN1): 가입 진입 시 첫 화면 — 계정 종류 선택.
  //   null 이면 chooser 노출, 선택 후엔 해당 가입 form 노출.
  SignupAccountType? _selectedAccountType;

  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _socialCtrl = TextEditingController();
  // Build 324: 친구 추천 invite code 입력 (optional). signUp 직후 자동 적용.
  //   복귀+신규 시뮬레이션 발견 — 코드 입력 채널이 premium 화면에만 있어
  //   viral loop 동작 안 함. signUp 흐름에 노출 → 친구가 코드 주면 즉시 사용.
  final _inviteCodeCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _isLoading = false;
  String? _error;
  String _selectedCountry = '대한민국';
  String _selectedFlag = '🇰🇷';

  // ── 검증 상태 ──
  String? _usernameError; // 실시간 아이디 에러
  String? _passwordError; // 실시간 비밀번호 에러
  bool _usernameTaken = false;

  // ── 동의 상태 ──
  bool _agreePrivacy = false;
  bool _agreeTerms = false; // 이용약관 + 커뮤니티 가이드라인 동의
  bool _agreeLocation = false; // 동의 체크
  // Build 276 (P0 GDPR/KISA): 만 14세 이상 self-attestation.
  // 한국 정보통신망법 제31조 + GDPR Art.8 (EU 16세 미만 별도 동의 필요).
  // 향후 launch 직전 생년월일 입력으로 강화 예정. 베타에선 self-attestation 으로 시작.
  bool _agreeAgeAbove14 = false;

  // Build 296: GDPR Art.8 default 는 16+. EU 회원국 선택 시 16 으로 강화.
  // Build 300 (BLOCKER privacy audit): 27 EU + 3 EEA 모두 포함. 이전엔 4국만
  // → NL/SE/PL/BE/FI/AT/IS/LI/NO 등 EU 청소년이 14+ 동의로 우회 가입 가능.
  // 일부 회원국은 Art.8 derogation 으로 13~15 로 낮춤 — 본 구현은 보수적
  // (가장 높은) 16 으로 통일. 후속 PR 에서 per-country lookup 으로 세분화 가능.
  static const _euGdprCountries = <String>{
    // EU 27 (한국어 country picker 라벨)
    '프랑스', '독일', '이탈리아', '스페인',
    '네덜란드', '폴란드', '벨기에', '오스트리아',
    '스웨덴', '덴마크', '핀란드', '아일랜드',
    '포르투갈', '그리스', '체코', '루마니아',
    '헝가리', '슬로바키아', '불가리아', '크로아티아',
    '슬로베니아', '리투아니아', '라트비아', '에스토니아',
    '키프로스', '룩셈부르크', '몰타',
    // EEA (EU 외 GDPR 적용)
    '노르웨이', '아이슬란드', '리히텐슈타인',
  };
  int get _minAge => _euGdprCountries.contains(_selectedCountry) ? 16 : 14;
  // Build 286 (P0 KISA 정보통신망법 제24조의2): 개인정보 제3자 제공 동의.
  // Firebase / Stadia Maps / RevenueCat 등 처리 위탁 업체 명시. 별도 동의로
  // privacy 동의와 분리 — 사용자가 의식적으로 인지하도록 함.
  bool _agreeThirdPartySharing = false;
  // Build 411 (launch): 광고성 정보 수신 동의 (선택). 한국 정보통신망법 제50조 —
  //   마케팅/광고 푸시는 필수 동의와 분리된 별도 opt-in 이어야 함. 가입 필수
  //   아님(_canSignUp 에 미포함). 동의 시 consent_marketing_ts 기록.
  bool _agreeMarketing = false;

  // Build 286 (보안 A3): 동의 audit log 를 Keychain/EncryptedSharedPreferences
  // 로 옮김. 이전엔 SharedPreferences plain text 라 device root 환경에서 위변
  // 조 가능. 일반 prefs 와 비교해 forensic 무결성 확보.
  static const FlutterSecureStorage _consentStore = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // ── 핸드폰 번호 (필수) + 국가코드 + 인증 수단 선택 ──
  final _phoneCtrl = TextEditingController();
  String _selectedCountryCode = '+82'; // 국가번호 기본값
  String _verifyMethod = 'email'; // 'email' or 'phone'
  String? _phoneError; // 전화번호 검증 에러
  bool _locationGranted = false; // 실제 OS 권한 허용 여부

  /// 국가별 전화번호 국가코드 맵
  static const _countryCodes = {
    '대한민국': '+82',
    '일본': '+81',
    '미국': '+1',
    '프랑스': '+33',
    '영국': '+44',
    '독일': '+49',
    '이탈리아': '+39',
    '스페인': '+34',
    '브라질': '+55',
    '인도': '+91',
    '중국': '+86',
    '호주': '+61',
    '캐나다': '+1',
  };

  // ── 이메일 인증 OTP 상태 ──
  bool _showOtpScreen = false; // OTP 입력 화면 표시 여부
  final _otpCtrl = TextEditingController();
  String? _otpError;
  // Build 409 (sim P1.1): 이메일 발송이 실제로 실패했는지 (오답 입력과 구분).
  //   on-screen 코드 fallback 노출은 이 flag 가 true 일 때만 (또는 debug/미설정).
  bool _otpSendFailed = false;
  String? _devOtpCode; // 개발용: 생성된 OTP 코드 (실제 배포시 제거)
  int _otpCountdown = 0; // 남은 시간 (초)
  Timer? _otpTimer; // 타이머

  // 가입 버튼 활성화 조건 (개인정보 + 이용약관 + 만 14세 이상 + 제3자 제공 동의)
  // 전화번호는 선택 사항 — SMS 인증 미사용 중.
  // Build 276: _agreeAgeAbove14 추가 (GDPR/KISA 미성년자 보호).
  // Build 286: _agreeThirdPartySharing 추가 (KISA 제24조의2 + GDPR Art.6).
  bool get _canSignUp =>
      _agreePrivacy &&
      _agreeTerms &&
      _agreeAgeAbove14 &&
      _agreeThirdPartySharing &&
      !_isLoading;

  @override
  void initState() {
    super.initState();
    _loadOnboardingCountry();
    // 실시간 검증 리스너
    _usernameCtrl.addListener(_validateUsername);
    _passCtrl.addListener(_validatePassword);
    _phoneCtrl.addListener(_onPhoneChanged);
  }

  /// Build 406 (PR-OO5 시뮬레이션 P1 #2): chooser 로 돌아갈 때 form state
  ///   reset. 이전엔 _selectedAccountType 만 null 로 reset → email/username/
  ///   password/inviteCode/agree* 모두 잔존 → 사용자가 Brand 로 입력하다가
  ///   일반으로 갈아탈 때 PII 누설 + 동의 carry-over 가능.
  ///
  ///   reset 대상:
  ///   - 모든 TextEditingController (text 비움)
  ///   - 검증 에러 상태 (_usernameError / _passwordError / _phoneError / _otpError)
  ///   - 동의 체크박스 (privacy / terms / age / location / thirdParty)
  ///   - OTP 진행 상태 (_showOtpScreen / _devOtpCode / _otpCountdown / _otpTimer)
  void _resetSignupFormAndReturnToChooser() {
    _otpTimer?.cancel();
    setState(() {
      _selectedAccountType = null;
      _emailCtrl.clear();
      _usernameCtrl.clear();
      _passCtrl.clear();
      _socialCtrl.clear();
      _inviteCodeCtrl.clear();
      _phoneCtrl.clear();
      _otpCtrl.clear();
      _usernameError = null;
      _passwordError = null;
      _usernameTaken = false;
      _phoneError = null;
      _otpError = null;
      _error = null;
      _agreePrivacy = false;
      _agreeTerms = false;
      _agreeLocation = false;
      _agreeAgeAbove14 = false;
      _agreeThirdPartySharing = false;
      _agreeMarketing = false;
      _showOtpScreen = false;
      _devOtpCode = null;
      _otpSendFailed = false;
      _otpCountdown = 0;
    });
  }

  void _onPhoneChanged() {
    // _canSignUp 갱신 (전화번호 입력 여부에 따라 버튼 활성화)
    setState(() {});
  }

  Future<void> _loadOnboardingCountry() async {
    final data = await AuthService.getOnboardingCountry();
    if (mounted) {
      setState(() {
        _selectedCountry = data['country'] ?? '대한민국';
        _selectedFlag = data['countryFlag'] ?? '🇰🇷';
        _selectedCountryCode = _countryCodes[_selectedCountry] ?? '+82';
      });
    }
  }

  Timer? _usernameCheckDebounce;

  void _validateUsername() {
    final err = AuthService.validateUsername(_usernameCtrl.text, langCode: _langCode);
    if (_usernameError != err) setState(() => _usernameError = err);

    // 포맷 오류 있으면 중복 체크 스킵
    if (err != null) {
      if (_usernameTaken) setState(() => _usernameTaken = false);
      return;
    }
    // 디바운스 중복 체크 (입력 멈춘 후 400ms)
    _usernameCheckDebounce?.cancel();
    final candidate = _usernameCtrl.text.trim();
    if (candidate.isEmpty) return;
    _usernameCheckDebounce = Timer(const Duration(milliseconds: 400), () async {
      final taken = await AuthService.isUsernameTaken(candidate);
      if (!mounted) return;
      // 입력값이 디바운스 도중 바뀌었으면 결과 무시
      if (_usernameCtrl.text.trim() != candidate) return;
      if (_usernameTaken != taken) setState(() => _usernameTaken = taken);
    });
  }

  void _validatePassword() {
    final err = AuthService.validatePassword(_passCtrl.text, langCode: _langCode);
    if (_passwordError != err) setState(() => _passwordError = err);
  }

  static const _countries = [
    {'name': '대한민국', 'flag': '🇰🇷'},
    {'name': '일본', 'flag': '🇯🇵'},
    {'name': '미국', 'flag': '🇺🇸'},
    {'name': '프랑스', 'flag': '🇫🇷'},
    {'name': '영국', 'flag': '🇬🇧'},
    {'name': '독일', 'flag': '🇩🇪'},
    {'name': '이탈리아', 'flag': '🇮🇹'},
    {'name': '스페인', 'flag': '🇪🇸'},
    {'name': '브라질', 'flag': '🇧🇷'},
    {'name': '인도', 'flag': '🇮🇳'},
    {'name': '중국', 'flag': '🇨🇳'},
    {'name': '호주', 'flag': '🇦🇺'},
    {'name': '캐나다', 'flag': '🇨🇦'},
  ];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    _socialCtrl.dispose();
    _inviteCodeCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _otpTimer?.cancel();
    _usernameCheckDebounce?.cancel();
    super.dispose();
  }

  String get _langCode => LanguageConfig.getLanguageCode(_selectedCountry);
  AppL10n get _l10n => AppL10n.of(_langCode);

  /// 전체 전화번호 (E.164 형식) 생성. 입력이 비어 있으면 빈 문자열 반환.
  String get _fullPhoneNumber {
    final raw = _phoneCtrl.text.trim();
    if (raw.isEmpty) return '';
    return SmsService.normalizePhoneNumber(raw, _selectedCountryCode);
  }

  /// Step 1: 폼 검증 후 OTP 발송 화면으로 전환
  Future<void> _signUp() async {
    final l10n = _l10n;
    if (!_agreePrivacy) {
      setState(() => _error = l10n.authMustAgreePrivacy);
      return;
    }
    if (!_agreeTerms) {
      setState(() => _error = l10n.authMustAgreeTerms);
      return;
    }
    if (!_agreeAgeAbove14) {
      setState(() => _error = l10n.authMustAgreeAge(_minAge));
      return;
    }
    if (!_agreeThirdPartySharing) {
      setState(() => _error = l10n.authMustAgreeThirdParty);
      return;
    }
    // 폼 기본 검증
    final emailVal = _emailCtrl.text.trim();
    if (emailVal.isEmpty) {
      setState(() => _error = l10n.authEnterEmail);
      return;
    }
    final emailErr = AuthService.validateEmail(emailVal, langCode: _langCode);
    if (emailErr != null) {
      setState(() => _error = emailErr);
      return;
    }
    // 전화번호는 선택 사항 (SMS 인증 미사용). 입력된 경우에만 형식 검증.
    final phoneVal = _phoneCtrl.text.trim();
    if (phoneVal.isNotEmpty) {
      final digitsOnly = phoneVal.replaceAll(RegExp(r'[^\d]'), '');
      if (digitsOnly.length < 6) {
        setState(() => _error = l10n.authPhoneInvalid);
        return;
      }
    }

    final taken = await AuthService.isEmailTaken(emailVal);
    if (taken) {
      setState(() => _error = l10n.authEmailTaken);
      return;
    }

    // 네트워크 연결 확인 (이메일 발송 전)
    if (!ConnectivityService.instance.isOnline) {
      setState(() => _error = l10n.offlineDisconnected);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // 이메일 OTP 생성 (Rate limit 초과 시 null)
    final code = AuthService.generateEmailOtp(emailVal);

    if (!mounted) return;
    if (code == null) {
      final cooldown = AuthService.otpCooldownSecondsRemaining;
      setState(() {
        _isLoading = false;
        _error = cooldown > 0
            ? l10n.authOtpRetryLater(cooldown)
            : l10n.authOtpLimitExceeded;
      });
      return;
    }

    // 이메일로 OTP 발송 (Resend → SendGrid 폴백, 둘 다 미설정 시 화면 fallback)
    final sendErr = await EmailService.sendOtp(
      to: emailVal,
      code: code,
      langCode: _langCode,
    );
    if (!mounted) return;
    // Build 295: 발송 실패해도 OTP 화면 진입 + 화면에 코드 fallback 노출.
    // 이전엔 sendErr 면 early return → 사용자가 OTP 입력란 자체 못 보고 막힘.
    setState(() {
      _isLoading = false;
      _showOtpScreen = true;
      _devOtpCode = code;
      // Build 415: sendErr 를 OTP 필드 errorText 로 띄우면 '코드 입력 전부터 오류'
      //   처럼 보여 혼란(정상 발송인데도 빨간 메세지). 발송 실패는 _otpSendFailed
      //   로 별도 안내(화면 fallback 코드 블록)하고, errorText 는 '오답 검증' 전용.
      _otpError = null;
      // Build 409 (sim P1.1): 코드 화면 노출은 '발송 실패' 시에만. 이전엔
      //   _otpError != null 로 노출 조건을 걸어 '오답 입력' 시에도 진짜 코드가
      //   화면에 떠 OTP 보안 무력화. 발송 실패 여부를 별도 flag 로 추적.
      _otpSendFailed = sendErr != null;
      _otpCountdown = AuthService.otpRemainingSeconds;
    });
    _startOtpTimer();
  }

  /// Step 2: OTP 확인 후 실제 회원가입 완료
  Future<void> _verifyOtpAndComplete() async {
    final emailVal = _emailCtrl.text.trim();
    final otpVal = _otpCtrl.text.trim();

    if (otpVal.length != 6) {
      setState(() => _otpError = _l10n.authEnterOtpCode);
      return;
    }

    // 이메일 OTP 검증
    final otpErr = AuthService.verifyEmailOtp(emailVal, otpVal, langCode: _langCode);

    if (otpErr != null) {
      setState(() => _otpError = otpErr);
      return;
    }

    // OTP 인증 성공 → 실제 회원가입 진행
    setState(() {
      _isLoading = true;
      _otpError = null;
    });

    final err = await AuthService.signUp(
      username: _usernameCtrl.text,
      password: _passCtrl.text,
      email: emailVal,
      country: _selectedCountry,
      countryFlag: _selectedFlag,
      languageCode: LanguageConfig.getLanguageCode(_selectedCountry),
      socialLink: _socialCtrl.text.isNotEmpty ? _socialCtrl.text : null,
      phoneNumber: _fullPhoneNumber,
      verifyMethod: _verifyMethod,
      langCode: _langCode,
      // Build 405 (PR-NN2): NN1 chooser 에서 선택한 계정 종류 전달.
      //   Brand 선택 시 brandName 도 같이 — username 을 fallback 으로 사용
      //   (브랜드명 별도 입력 step 은 후속 PR 에서 강화 예정).
      isBrand: _selectedAccountType == SignupAccountType.brand,
      brandName: _selectedAccountType == SignupAccountType.brand
          ? _usernameCtrl.text.trim()
          : null,
    );

    if (!mounted) return;

    if (err != null) {
      setState(() {
        _isLoading = false;
        _otpError = err;
      });
      return;
    }

    // 동의 타임스탬프 저장 (GDPR/개인정보보호법 대응)
    // Build 286: SharedPreferences → FlutterSecureStorage 로 이전.
    // forensic 무결성 + device root 환경에서 위변조 차단.
    try {
      final ts = DateTime.now().toIso8601String();
      await _consentStore.write(key: 'consent_privacy_ts', value: ts);
      await _consentStore.write(key: 'consent_terms_ts', value: ts);
      // Build 276: 만 14세 이상 동의 timestamp (KISA + GDPR audit log).
      await _consentStore.write(key: 'consent_age_above14_ts', value: ts);
      // Build 286: 제3자 정보 제공 동의 timestamp (KISA 제24조의2).
      await _consentStore.write(
        key: 'consent_third_party_sharing_ts',
        value: ts,
      );
      // Build 411 (launch): 광고성 정보 수신 동의(선택) — 체크 시에만 기록.
      //   미체크면 키를 명시적으로 삭제(이전 동의 잔존 방지). 정보통신망법
      //   제50조 — opt-in 증빙 + export 에서 읽는 consent_marketing_ts 와 연결.
      if (_agreeMarketing) {
        await _consentStore.write(key: 'consent_marketing_ts', value: ts);
      } else {
        await _consentStore.delete(key: 'consent_marketing_ts');
      }
    } catch (_) {}

    // Build 262: 신규 가입 무료 Premium 부여 (cold-start 해소).
    // Build 271: 7일 → 3일 단축.
    // Build 298 (HIGH audit): server-side claim 검증 — email-hash 기반.
    // Build 299 (BLOCKER fix): tryClaimWelcomeTrial 는 _currentUser.id != 'guest'
    // 가 전제. 이전 흐름은 setUser 전에 호출 → guest 가드로 early return →
    // 모든 신규 가입자 trial 미부여 회귀. setUser 가 끝난 다음 trial 부여.
    final user = await AuthService.getCurrentUser();
    // Build 311: 신규 가입은 무조건 온보딩 표시 — 같은 디바이스에 다른 사람이
    // 가입할 때도 동작. 이전 사용자의 markSeen 잔존 무시.
    await AuthService.resetOnboardingFlags();

    // Build 368 (PR-CC3 P0 #13): tryClaimWelcomeTrial + invite code 적용을
    //   onSignupSuccess **앞**으로 이동. 이전엔 onSignupSuccess 가 Navigator
    //   .pushReplacementNamed('/onboarding') 으로 SignupTab dispose →
    //   직후 try 블록의 `if (!mounted) return` early-return → trial 부여
    //   0% 성공. Build 299 fix 의도였으나 onSignupSuccess 순서 잘못으로 회귀.
    //   cold-start retry 가 다음 launch 에 메우지만 첫 세션 Free 권한 회귀.
    try {
      if (mounted) {
        final purchase = context.read<PurchaseService>();
        final state = context.read<AppState>();
        // Build 406 (PR-OO4 시뮬레이션 P1 #3): Brand 가입자는 welcome trial
        //   부여 skip. Brand 는 발송 중심 권한 — trial Premium 부여 의미 없음
        //   + 만료 안내 노출이 혼란 유발. 일반 회원 (general) 만 부여.
        if (_selectedAccountType != SignupAccountType.brand) {
          await state.tryClaimWelcomeTrial(
            email: _emailCtrl.text.trim().toLowerCase(),
            grant: () => purchase.grantWelcomeTrial(days: 3),
          );
        }
        // Build 324: 친구 invite code 자동 적용 — viral loop 작동.
        //   양쪽 (가입자 + 추천인) 모두 +5 invite reward credits.
        //   premium 화면에서도 입력 가능하지만 signUp 시점 입력이 가장 효과적.
        //   Brand 가입자도 invite code 사용 가능 (네트워킹 효과 동일).
        final code = _inviteCodeCtrl.text.trim();
        if (code.isNotEmpty) {
          unawaited(state.applyInviteCode(code));
        }
      }
    } catch (_) {}

    // onSignupSuccess 가 SignupTab 을 dispose 할 수 있으므로 마지막에 호출.
    if (user != null) await widget.onSignupSuccess(user);
  }

  /// OTP 재발송 (이메일)
  /// Build 295: 실제 이메일 발송 호출 추가 — 이전엔 코드만 새로 생성하고 이메일
  /// 발송이 빠져 release 빌드에서 "재발송 눌러도 코드 안 옴" 회귀였음.
  Future<void> _resendOtp() async {
    _otpTimer?.cancel();
    final emailVal = _emailCtrl.text.trim();
    final code = AuthService.generateEmailOtp(emailVal);
    if (code == null) {
      final cooldown = AuthService.otpCooldownSecondsRemaining;
      setState(() {
        _otpError = cooldown > 0
            ? _l10n.authOtpResendWait(cooldown)
            : _l10n.authOtpLimitExceeded;
      });
      return;
    }
    // Build 295: 실제 이메일 발송. 실패해도 on-screen fallback 노출 가능.
    final sendErr = await EmailService.sendOtp(
      to: emailVal,
      code: code,
      langCode: _langCode,
    );
    if (!mounted) return;
    setState(() {
      _otpCtrl.clear();
      _otpError = sendErr; // 발송 실패 시 사용자에게 알림 + 화면 fallback 코드 노출
      // Build 409 (sim P1.1): 재발송 성공 시 send-failed flag 해제 (코드 숨김).
      _otpSendFailed = sendErr != null;
      _devOtpCode = code;
      _otpCountdown = AuthService.otpRemainingSeconds;
    });
    _startOtpTimer();
  }

  void _startOtpTimer() {
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = AuthService.otpRemainingSeconds;
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _otpCountdown = remaining);
      if (remaining <= 0) timer.cancel();
    });
  }

  /// 국가코드 선택 바텀시트
  void _showCountryCodePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          constraints: const BoxConstraints(maxHeight: 400),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.public_rounded, color: AppColors.teal, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _l10n.authSelectCountryCode,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _countries.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: AppColors.bgSurface,
                  ),
                  itemBuilder: (_, i) {
                    final country = _countries[i];
                    final name = country['name']!;
                    final flag = country['flag']!;
                    final code = _countryCodes[name] ?? '+1';
                    // Build 296 (P2 audit): 코드(+1) 가 미국/캐나다 둘에 공유돼
                    // 코드만 비교하면 양쪽 모두 selected 로 보이는 cosmetic 버그.
                    // 국가명 기준 비교로 정확히 한 행만 강조.
                    final isSelected = name == _selectedCountry;
                    return ListTile(
                      leading: Text(flag, style: const TextStyle(fontSize: 24)),
                      title: Text(
                        CountryL10n.localizedName(name, _langCode),
                        style: TextStyle(
                          color: isSelected ? AppColors.teal : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      trailing: Text(
                        code,
                        style: TextStyle(
                          color: isSelected ? AppColors.teal : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedCountryCode = code;
                          // 국가 선택도 동기화
                          // Build 299 (MED audit): EU GDPR ↔ KR ICT 경계를 넘어
                          // 가면 _minAge 가 14 ↔ 16 으로 바뀜. 사용자가 이미
                          // 14+ 동의를 했었더라도 카드 텍스트가 16+ 로 바뀌면
                          // 동의 의미가 달라지므로 명시적 재동의 요구 (체크
                          // 해제). 안전한 fallback — 다시 체크하면 1초 비용.
                          final prevIsEu =
                              _euGdprCountries.contains(_selectedCountry);
                          final newIsEu = _euGdprCountries.contains(name);
                          if (prevIsEu != newIsEu) {
                            _agreeAgeAbove14 = false;
                          }
                          _selectedCountry = name;
                          _selectedFlag = flag;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build 296: 전체 동의 — 필수 4건 + 위치(선택) 일괄 토글. 위치는 OS 권한
  // 흐름을 그대로 호출하므로 거부 시 위치만 해제, 나머지 4건은 ON 보존.
  // Build 414 (sim100 #16): 광고성 수신(_agreeMarketing)은 전체동의에서 제외.
  //   정보통신망법 제50조 — 마케팅 수신은 필수 항목과 번들링 불가, 명시적
  //   개별 opt-in 이어야 한다. 전체동의 = 필수 4건 + 위치(선택)만.
  bool get _agreeAll =>
      _agreePrivacy &&
      _agreeTerms &&
      _agreeAgeAbove14 &&
      _agreeThirdPartySharing &&
      _agreeLocation;

  Future<void> _onAgreeAllTap(bool? checked) async {
    final next = checked ?? false;
    setState(() {
      _agreePrivacy = next;
      _agreeTerms = next;
      _agreeAgeAbove14 = next;
      _agreeThirdPartySharing = next;
      // Build 414 (sim100 #16): 광고성 수신은 전체동의에서 제외(정보통신망법
      //   제50조 번들링 금지) — _agreeMarketing 은 사용자가 개별 체크해야만 ON.
    });
    if (next) {
      if (!_agreeLocation) {
        await _onLocationConsentTap(true);
      }
    } else {
      setState(() {
        _agreeLocation = false;
        _locationGranted = false;
      });
    }
  }

  /// 위치 동의 체크박스 탭 → OS 권한 요청
  Future<void> _onLocationConsentTap(bool? checked) async {
    if (checked != true) {
      setState(() {
        _agreeLocation = false;
        _locationGranted = false;
      });
      return;
    }
    // 동의 체크 시 즉시 OS 위치 권한 요청
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    final granted =
        permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    if (!mounted) return;
    // Build 296 (P1 audit): `deniedForever` 는 사용자가 시스템 설정에서만 풀
    // 수 있는 상태이므로 동의 체크를 자동 ON 으로 두면 `_agreeAll` 이 false
    // positive 가 됨. 명시적 OFF + Open Settings 안내가 정확한 fallback.
    setState(() {
      _agreeLocation = granted;
      _locationGranted = granted;
    });
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l10n.authLocationDenied),
          backgroundColor: AppColors.bgCard,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: _l10n.authOpenSettings,
            textColor: AppColors.teal,
            onPressed: () => Geolocator.openAppSettings(),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showOtpScreen) return _buildOtpScreen(context);
    // Build 405 (PR-NN1): 가입 진입 첫 화면은 계정 종류 선택. 사용자가
    //   본인이 일반/브랜드 어느 흐름에 들어가는지 명시 인지 후 form 진입.
    if (_selectedAccountType == null) return _buildAccountTypeChooser(context);
    return _buildSignupForm(context);
  }

  /// Build 405 (PR-NN1): 회원 가입 시 첫 화면 — 일반 vs 브랜드 선택.
  ///
  /// 큰 카드 2장 + 각각 설명/이점 3개 + 가입 버튼. 가입 후 변경 가능
  /// (settings) 임을 subtitle 에 명시. 지도/위치는 공유되지만 인박스/홈은
  /// 분리됨을 사용자에게 사전 인지.
  Widget _buildAccountTypeChooser(BuildContext context) {
    final l10n = _l10n;
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 28, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.accountTypeChooserTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.accountTypeChooserSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _AccountTypeCard(
            emoji: '🆓',
            title: l10n.accountTypeGeneralTitle,
            subtitle: l10n.accountTypeGeneralSubtitle,
            bullets: [
              l10n.accountTypeGeneralBullet1,
              l10n.accountTypeGeneralBullet2,
              l10n.accountTypeGeneralBullet3,
            ],
            ctaLabel: l10n.accountTypeChooseGeneral,
            accentColor: AppColors.teal,
            onTap: () => setState(() {
              _selectedAccountType = SignupAccountType.general;
            }),
          ),
          const SizedBox(height: 16),
          _AccountTypeCard(
            emoji: '🏷️',
            title: l10n.accountTypeBrandTitle,
            subtitle: l10n.accountTypeBrandSubtitle,
            bullets: [
              l10n.accountTypeBrandBullet1,
              l10n.accountTypeBrandBullet2,
              l10n.accountTypeBrandBullet3,
            ],
            ctaLabel: l10n.accountTypeChooseBrand,
            accentColor: AppColors.coupon,
            onTap: () => setState(() {
              _selectedAccountType = SignupAccountType.brand;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm(BuildContext context) {
    final l10n = _l10n;
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Build 405 (PR-NN1): 선택한 계정 종류 표시 + 변경 link. 사용자가
          //   잘못 선택했음을 가입 도중에도 인지 → chooser 로 돌아갈 수 있음.
          _SelectedAccountTypeBar(
            accountType: _selectedAccountType!,
            generalLabel: l10n.accountTypeGeneralTitle,
            brandLabel: l10n.accountTypeBrandTitle,
            changeLabel: l10n.accountTypeChangeLink,
            onChange: _resetSignupFormAndReturnToChooser,
          ),
          const SizedBox(height: 12),
          if (_error != null) _ErrorBanner(message: _error!),

          // ── 1. 이메일 ──────────────────────────────────────────────────────
          _InputField(
            controller: _emailCtrl,
            label: l10n.email,
            hint: 'example@email.com',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),

          // ── 2. 아이디 ──────────────────────────────────────────────────────
          _InputField(
            controller: _usernameCtrl,
            label: l10n.authId,
            hint: l10n.authUsernameHint,
            icon: Icons.person_rounded,
          ),
          if (_usernameError != null)
            _FieldError(message: _usernameError!)
          else if (_usernameTaken)
            _FieldError(message: l10n.authUsernameTaken)
          else
            // Build 415: 아이디 규칙을 필드 아래 helper 로 노출 (hint 잘림 해소).
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12, right: 4),
              child: Text(
                l10n.authUsernameRule,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ),
          const SizedBox(height: 12),

          // ── 3. 비밀번호 ────────────────────────────────────────────────────
          _InputField(
            controller: _passCtrl,
            label: l10n.password,
            hint: l10n.authPasswordHintSignup,
            icon: Icons.lock_rounded,
            obscureText: _obscurePass,
            suffixIcon: IconButton(
              // Build 423 (sim-crosscut P2): a11y — 상태 반영 tooltip.
              tooltip: _obscurePass
                  ? l10n.koEn('비밀번호 표시', 'Show password')
                  : l10n.koEn('비밀번호 숨기기', 'Hide password'),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
              icon: Icon(
                _obscurePass
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
            ),
          ),
          if (_passwordError != null) _FieldError(message: _passwordError!),
          const SizedBox(height: 12),

          // ── 4. 국가 선택 ───────────────────────────────────────────────────
          GestureDetector(
            onTap: _pickCountry,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.bgSurface),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _selectedFlag,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.authResidenceCountry,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          CountryL10n.localizedName(_selectedCountry, _langCode),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── 5. SNS 링크 ────────────────────────────────────────────────────
          _InputField(
            controller: _socialCtrl,
            label: l10n.authSnsLink,
            hint: 'https://instagram.com/...',
            icon: Icons.link_rounded,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),

          // ── 5.5 친구 추천 코드 (선택) — Build 324 ──────────────────────────
          // 가입 직후 자동 applyInviteCode 호출 → 양쪽 보상. signUp 시점이
          // viral loop 의 conversion peak — premium 화면에서만 가능하던 기존
          // 흐름의 친구 추천 트래킹 부재 해소 (복귀+신규 시뮬레이션 발견).
          _InputField(
            controller: _inviteCodeCtrl,
            label: l10n.authInviteCodeOptional,
            hint: l10n.authInviteCodeHint,
            icon: Icons.card_giftcard_rounded,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 12),

          // ── 5-1. 핸드폰 번호 (선택, 국가코드 포함) — SMS 인증 미사용 ───────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.authPhoneOptional,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 국가코드 드롭다운
                  GestureDetector(
                    onTap: _showCountryCodePicker,
                    child: Container(
                      width: 90,
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.bgSurface),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _selectedFlag,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _selectedCountryCode,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 전화번호 입력 필드
                  Expanded(
                    child: TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: '10-1234-5678',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(
                          Icons.phone_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        filled: true,
                        fillColor: AppColors.bgCard,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.bgSurface),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.bgSurface),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.teal,
                            width: 1.5,
                          ),
                        ),
                        errorText: _phoneError,
                        errorStyle: const TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.authPhoneHint,
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── 5-2. 이메일 인증 안내 ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.email_rounded, color: AppColors.teal, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.authVerifyViaEmail,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── 6-0. Build 296: 전체 동의 (필수 4 + 선택 위치 일괄 토글) ──────
          _AgreeAllCard(
            checked: _agreeAll,
            title: l10n.authAgreeAllTitle,
            description: l10n.authAgreeAllDesc(_minAge),
            onChanged: _onAgreeAllTap,
          ),
          const SizedBox(height: 12),

          // ── 6. 개인정보 동의 ───────────────────────────────────────────────
          _ConsentCard(
            checked: _agreePrivacy,
            icon: Icons.shield_outlined,
            iconColor: AppColors.teal,
            title: l10n.authPrivacyRequired,
            linkLabel: l10n.authViewContent,
            description: l10n.authPrivacyDesc,
            langCode: widget.langCode,
            onCheckChanged: (v) => setState(() => _agreePrivacy = v ?? false),
            onLinkTap: _openPrivacyPolicy,
          ),
          const SizedBox(height: 10),

          // ── 6-1. 이용약관 + 커뮤니티 가이드라인 동의 ──────────────────────
          _ConsentCard(
            checked: _agreeTerms,
            icon: Icons.gavel_rounded,
            iconColor: AppColors.gold,
            title: l10n.authTermsRequired,
            linkLabel: l10n.authViewContent,
            description: l10n.authTermsDesc,
            langCode: widget.langCode,
            onCheckChanged: (v) => setState(() => _agreeTerms = v ?? false),
            onLinkTap: _showTermsAndGuidelines,
          ),
          const SizedBox(height: 10),

          // ── 6-2. Build 276 (P0): 만 14세 이상 동의 (KISA 정보통신망법 제31조 +
          // GDPR Art.8). 현재 self-attestation. 향후 launch 직전 생년월일 강화.
          // Build 277: 한·영 분기 → 14언어 풀 번역.
          // Build 296: EU 회원국 (프랑스/독일/이탈리아/스페인) 선택 시 16+ 분기.
          _ConsentCard(
            checked: _agreeAgeAbove14,
            icon: Icons.cake_rounded,
            iconColor: AppColors.coupon,
            title: l10n.authAgeAboveTitle(_minAge),
            description: l10n.authAgeAboveDesc(_minAge),
            langCode: widget.langCode,
            onCheckChanged: (v) =>
                setState(() => _agreeAgeAbove14 = v ?? false),
          ),
          const SizedBox(height: 10),

          // ── 6-3. Build 286 (P0 KISA 제24조의2): 제3자 정보 제공 동의.
          // Firebase / Stadia Maps / RevenueCat / Resend 처리 위탁 명시.
          // privacy 동의와 분리해 사용자가 의식적으로 인지하도록.
          _ConsentCard(
            checked: _agreeThirdPartySharing,
            icon: Icons.swap_horiz_rounded,
            iconColor: AppColors.gold,
            title: l10n.authThirdPartySharingTitle,
            linkLabel: l10n.authViewContent,
            description: l10n.authThirdPartySharingDesc,
            langCode: widget.langCode,
            onCheckChanged: (v) =>
                setState(() => _agreeThirdPartySharing = v ?? false),
            onLinkTap: _openPrivacyPolicy,
          ),
          const SizedBox(height: 10),

          // ── 7. 위치 동의 ───────────────────────────────────────────────────
          _ConsentCard(
            checked: _agreeLocation,
            icon: _locationGranted
                ? Icons.location_on_rounded
                : Icons.location_off_rounded,
            iconColor: _locationGranted ? AppColors.teal : AppColors.textMuted,
            title: l10n.authLocationOptional,
            description: l10n.authLocationDesc,
            langCode: widget.langCode,
            statusWidget: _locationGranted
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.teal,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.authGranted,
                        style: const TextStyle(color: AppColors.teal, fontSize: 11),
                      ),
                    ],
                  )
                : null,
            onCheckChanged: _onLocationConsentTap,
          ),
          const SizedBox(height: 10),

          // ── 7-1. Build 411 (launch): 광고성 정보 수신 동의 (선택). 정보통신망법
          //   제50조 — 마케팅 푸시는 필수 동의와 분리된 별도 opt-in. 가입 필수 아님.
          _ConsentCard(
            checked: _agreeMarketing,
            icon: Icons.campaign_rounded,
            iconColor: AppColors.gold,
            title: l10n.authMarketingOptional,
            description: l10n.authMarketingDesc,
            langCode: widget.langCode,
            onCheckChanged: (v) =>
                setState(() => _agreeMarketing = v ?? false),
          ),
          const SizedBox(height: 24),

          // ── 가입하기 버튼 ─────────────────────────────────────────────────
          _AuthButton(
            label: l10n.authSignupButton,
            emoji: '✨',
            isLoading: _isLoading,
            enabled: _canSignUp,
            onTap: _signUp,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpScreen(BuildContext context) {
    final l10n = _l10n;
    final email = _emailCtrl.text.trim();
    final expired = _otpCountdown <= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 뒤로가기
          GestureDetector(
            onTap: () {
              _otpTimer?.cancel();
              setState(() {
                _showOtpScreen = false;
                _otpCtrl.clear();
                _otpError = null;
              });
            },
            child: Row(
              children: [
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.authBackToEmail,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 아이콘 + 제목
          Center(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    size: 32,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.authEmailVerification,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.authOtpSent(email),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // OTP 코드 표시:
          //   - DEBUG 빌드: 항상 표시
          //   - RELEASE 빌드: SendGrid/Resend 미설정 시 OR 발송 실패 시 표시
          //     → 사용자가 "이메일 안 옴" 으로 막히는 회귀 차단 (Build 295)
          // Build 409 (sim P1.1): 오답 입력(_otpError)이 아니라 실제 발송 실패
          //   (_otpSendFailed) 또는 debug/미설정 시에만 코드 fallback 노출.
          if ((kDebugMode ||
                  !EmailService.isConfigured ||
                  _otpSendFailed) &&
              _devOtpCode != null &&
              _devOtpCode!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.coupon.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.coupon.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.authBetaCodeFallback,
                    style: TextStyle(
                      color: AppColors.coupon.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _devOtpCode!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.coupon,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.koEn('위 코드를 아래 입력란에 넣어주세요',
                        'Enter the code above into the field below'),
                    style: TextStyle(
                      color: AppColors.coupon.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // OTP 입력 필드 (6자리)
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            // Build 416 (sim100 P2/P3): iOS 메일/문자 OTP 자동완성 활성 +
            //   숫자만 허용 → 비숫자 6자가 잘못된 자동검증을 발사하던 경계 차단.
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 12,
            ),
            decoration: InputDecoration(
              hintText: '------',
              hintStyle: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.4),
                fontSize: 28,
                letterSpacing: 12,
              ),
              counterText: '',
              filled: true,
              fillColor: AppColors.bgCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.textMuted.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.textMuted.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
              ),
              errorText: _otpError,
              errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
            ),
            // Build 415: 6자리 채우면 확인 버튼 없이 자동 검증. 잘못된 코드일
            //   때만 errorText 노출, 입력 중에는 에러 초기화. (iOS OTP 자동완성도
            //   한 번에 6자 채워져 자동 검증됨)
            onChanged: (val) {
              if (_otpError != null) setState(() => _otpError = null);
              if (val.trim().length == 6 && !_isLoading && !expired) {
                FocusScope.of(context).unfocus();
                _verifyOtpAndComplete();
              }
            },
          ),
          const SizedBox(height: 12),

          // 카운트다운 + 재발송
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!expired) ...[
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.authExpiresIn('${(_otpCountdown ~/ 60).toString().padLeft(2, '0')}:${(_otpCountdown % 60).toString().padLeft(2, '0')}'),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              GestureDetector(
                onTap: _resendOtp,
                child: Text(
                  expired ? l10n.authResendCode : l10n.authResend,
                  style: TextStyle(
                    color: expired ? AppColors.teal : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: expired ? FontWeight.w700 : FontWeight.normal,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Build 415: 확인 버튼 제거 — 6자리 입력 시 자동 검증(위 onChanged).
          //   진행 중에는 스피너만 노출해 가입 처리 중임을 안내.
          if (_isLoading)
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.teal,
                ),
              ),
            ),

          if (expired) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                l10n.authOtpExpired,
                style: TextStyle(color: Colors.red.shade400, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 개인정보 처리방침 페이지를 외부 브라우저로 열기
  /// [country]가 대한민국이면 한국어, 그 외는 영어 버전
  Future<void> _openPrivacyPolicy() async {
    final url = AppLinks.privacyPolicyForCountry(_selectedCountry);
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) _showPrivacyPolicy();
      }
    }
  }

  void _showPrivacyPolicy() {
    final l10n = _l10n;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.authPrivacyPolicy,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.authPrivacySec1Title,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.authPrivacySec1Body,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.authPrivacySec2Title,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.authPrivacySec2Body,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.authPrivacySec3Title,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.authPrivacySec3Body,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.authPrivacySec4Title,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.authPrivacySec4Body,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.authPrivacySec5Title,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.authPrivacySec5Body,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.authPrivacySec6Title,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.authPrivacySec6Body,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.authPrivacySec7Title,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.authPrivacySec7Body,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              setState(() => _agreePrivacy = true);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
            child: Text(
              l10n.authAgree,
              style: const TextStyle(color: AppColors.bgDeep),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.authClose,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  void _showTermsAndGuidelines() {
    final l10n = _l10n;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.communityGuidelinesTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 콘텐츠 열람 정책 ──
              Text(
                l10n.authPrivacySec5Title,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.authPrivacySec5Body,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              // ── 커뮤니티 가이드라인 ──
              Text(
                l10n.authPrivacySec7Title,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.authPrivacySec7Body,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              setState(() => _agreeTerms = true);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
            child: Text(
              l10n.authAgree,
              style: const TextStyle(color: AppColors.bgDeep),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.authClose,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  void _pickCountry() {
    final l10n = _l10n;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SizedBox(
          height: 420,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.authSelectResidenceCountry,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.authClose,
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              // 언어 안내 배너
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🌐', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.languageNotice,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: _countries.map((c) {
                    final langCode = LanguageConfig.getLanguageCode(c['name']!);
                    final langName = LanguageConfig.getLanguageName(langCode);
                    return ListTile(
                      leading: Text(
                        c['flag']!,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        CountryL10n.localizedName(c['name']!, _langCode),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        langName,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      trailing: _selectedCountry == c['name']
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.teal,
                              size: 18,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          // Build 416 (sim100 P1): 거주국가가 EU(16세)↔비EU(14세)
                          //   경계를 넘으면 연령 동의 리셋 — 전화 picker 와 동일
                          //   가드. 이전엔 14세 동의가 16세 동의로 무단 승격(GDPR
                          //   Art.8 우회)되던 회귀.
                          final prevIsEu =
                              _euGdprCountries.contains(_selectedCountry);
                          final newIsEu =
                              _euGdprCountries.contains(c['name']);
                          if (prevIsEu != newIsEu) _agreeAgeAbove14 = false;
                          _selectedCountry = c['name']!;
                          _selectedFlag = c['flag']!;
                          _selectedCountryCode = _countryCodes[c['name']!] ?? '+1';
                        });
                        Navigator.pop(ctx);
                        // 언어 안내 스낵바
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.authLanguageSet(langName)),
                            backgroundColor: AppColors.bgCard,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 공통 위젯 ─────────────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.gold, size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.bgSurface),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.bgSurface),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  const _AuthButton({
    required this.label,
    required this.emoji,
    required this.isLoading,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && !isLoading;
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: active ? onTap : null,
        // Build 426 (sim100 #37): 활성/비활성 명확 구분 — disabled* 색 명시 +
        //   비활성 외곽선 + 활성 그림자(compose 발송버튼과 동일 패턴).
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.bgDeep,
          disabledBackgroundColor: AppColors.bgSurface.withValues(alpha: 0.55),
          disabledForegroundColor: AppColors.textMuted.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: active
                ? BorderSide.none
                : BorderSide(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
          ),
          elevation: active ? 3 : 0,
          shadowColor: AppColors.gold.withValues(alpha: 0.5),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.bgDeep,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── 필드 인라인 에러 ───────────────────────────────────────────────────────────
class _FieldError extends StatelessWidget {
  final String message;
  const _FieldError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 12),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 12,
            color: AppColors.error,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 동의 카드 ─────────────────────────────────────────────────────────────────
class _ConsentCard extends StatelessWidget {
  final bool checked;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String langCode;
  final String? linkLabel;
  final Widget? statusWidget;
  final ValueChanged<bool?>? onCheckChanged;
  final VoidCallback? onLinkTap;

  const _ConsentCard({
    required this.checked,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.langCode,
    this.linkLabel,
    this.statusWidget,
    this.onCheckChanged,
    this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: checked
            ? AppColors.teal.withValues(alpha: 0.07)
            : AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: checked
              ? AppColors.teal.withValues(alpha: 0.4)
              : AppColors.bgSurface,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (statusWidget case final widget?) widget,
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: checked,
                onChanged: onCheckChanged,
                activeColor: AppColors.teal,
                side: const BorderSide(color: AppColors.textMuted),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  AppL10n.of(langCode).authIAgree,
                  style: TextStyle(
                    color: checked
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              if (linkLabel != null && onLinkTap != null)
                TextButton(
                  onPressed: onLinkTap,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    linkLabel!,
                    style: const TextStyle(color: AppColors.teal, fontSize: 11),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// Build 296: 전체 동의 카드 — 강조 스타일 (gold 보더 + teal-fill). 행 전체 탭 가능.
class _AgreeAllCard extends StatelessWidget {
  final bool checked;
  final String title;
  final String description;
  final ValueChanged<bool?>? onChanged;

  const _AgreeAllCard({
    required this.checked,
    required this.title,
    required this.description,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged?.call(!checked),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: checked
              ? AppColors.teal.withValues(alpha: 0.12)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: checked
                ? AppColors.teal
                : AppColors.gold.withValues(alpha: 0.6),
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: checked,
              onChanged: onChanged,
              activeColor: AppColors.teal,
              side: const BorderSide(color: AppColors.textMuted),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // v5: 별빛 배경 폐기, 클린 검정 유지 (CustomPaint 호환용 빈 페인터)
  }

  @override
  bool shouldRepaint(_) => false;
}

class _AuthDot extends StatelessWidget {
  const _AuthDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        color: AppColors.gold,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Build 405 (PR-NN1): 회원 가입 종류 선택 카드.
///
/// 큰 emoji + title + subtitle + bullet 3개 + 큰 CTA 버튼. 두 카드를
/// 위아래로 쌓아 사용자가 "내게 맞는 종류" 비교 후 선택. 카드 자체가
/// 탭 가능 (전체 탭 = CTA 동일).
class _AccountTypeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final List<String> bullets;
  final String ctaLabel;
  final Color accentColor;
  final VoidCallback onTap;

  const _AccountTypeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.ctaLabel,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...bullets.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    b,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: AppColors.bgDeep,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  ctaLabel,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Build 405 (PR-NN1): 가입 form 상단에 표시되는 "현재 선택된 계정 종류"
/// 안내 + 변경 link. 사용자가 가입 진행 중에도 선택을 인지 + 돌아갈 수 있음.
class _SelectedAccountTypeBar extends StatelessWidget {
  final SignupAccountType accountType;
  final String generalLabel;
  final String brandLabel;
  final String changeLabel;
  final VoidCallback onChange;

  const _SelectedAccountTypeBar({
    required this.accountType,
    required this.generalLabel,
    required this.brandLabel,
    required this.changeLabel,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final isBrand = accountType == SignupAccountType.brand;
    final accent = isBrand ? AppColors.coupon : AppColors.teal;
    final emoji = isBrand ? '🏷️' : '🆓';
    final label = isBrand ? brandLabel : generalLabel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onChange,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              changeLabel,
              style: TextStyle(
                color: accent,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
