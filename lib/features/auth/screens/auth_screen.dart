import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/localization/language_config.dart';
import '../../../core/config/app_links.dart';
import '../../../state/app_state.dart';
import '../../../core/services/purchase_service.dart';
import 'package:provider/provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
                const SizedBox(height: 40),
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
                      _LoginTab(onLoginSuccess: _onAuthSuccess),
                      _SignupTab(onSignupSuccess: _onAuthSuccess),
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
    return Column(
      children: [
        const Text('🍾', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDark],
          ).createShader(b),
          child: const Text(
            'Message in a Bottle',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '세상 어딘가의 당신에게',
          style: TextStyle(
            color: AppColors.textMuted.withValues(alpha: 0.8),
            fontSize: 13,
            letterSpacing: 2.0,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2D44)),
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
        tabs: const [
          Tab(text: '🔑  로그인'),
          Tab(text: '✨  회원가입'),
        ],
      ),
    );
  }

  Future<void> _onAuthSuccess(Map<String, String> userData) async {
    final state = context.read<AppState>();
    state.setUser(
      id: userData['id'] ?? '',
      username: userData['username'] ?? '',
      country: userData['country'] ?? '대한민국',
      countryFlag: userData['countryFlag'] ?? '🇰🇷',
      languageCode: userData['languageCode'],
      socialLink: userData['socialLink'],
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
  const _LoginTab({required this.onLoginSuccess});

  @override
  State<_LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends State<_LoginTab> {
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _error;

  static const _kRememberMe = 'login_remember_me';
  static const _kSavedUsername = 'login_saved_username';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_kRememberMe) ?? false;
    // 보안 강화를 위해 비밀번호 자동저장은 중단. 기존 저장본도 즉시 삭제.
    await prefs.remove('login_saved_password');
    await prefs.remove('login_saved_password_secure');
    if (!remember) return;
    final username = prefs.getString(_kSavedUsername) ?? '';
    if (username.isNotEmpty && mounted) {
      setState(() {
        _rememberMe = true;
        _usernameCtrl.text = username;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool(_kRememberMe, true);
      await prefs.setString(_kSavedUsername, _usernameCtrl.text.trim());
      // 비밀번호는 보관하지 않고 아이디만 기억.
      await prefs.remove('login_saved_password');
      await prefs.remove('login_saved_password_secure');
    } else {
      await prefs.remove(_kRememberMe);
      await prefs.remove(_kSavedUsername);
      await prefs.remove('login_saved_password');
      await prefs.remove('login_saved_password_secure');
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final err = await AuthService.login(
      username: _usernameCtrl.text,
      password: _passCtrl.text,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) _ErrorBanner(message: _error!),
          _InputField(
            controller: _usernameCtrl,
            label: '닉네임(아이디)',
            hint: 'Traveler_42',
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 14),
          _InputField(
            controller: _passCtrl,
            label: '비밀번호',
            hint: '6자 이상',
            icon: Icons.lock_rounded,
            obscureText: _obscurePass,
            suffixIcon: IconButton(
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
          GestureDetector(
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
                          color: Color(0xFF0D1421),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                const Text(
                  '아이디 · 비밀번호 기억하기',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _AuthButton(
            label: '로그인',
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
                    text: '아이디 찾기',
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
                    text: '비밀번호 찾기',
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
              '처음이신가요? 회원가입 탭에서 계정을 만들어보세요.',
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
                            email: 'test@lettergo.app',
                            country: '대한민국',
                            countryFlag: '🇰🇷',
                          );
                        }
                        final err = await AuthService.login(
                          username: testUser,
                          password: testPw,
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

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (sCtx, setS) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '아이디 찾기',
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
              const Text(
                '가입 시 등록한 이메일을 입력하면\n아이디와 임시 비밀번호를 발급해 드립니다.',
                style: TextStyle(
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
                  hintText: '가입 이메일',
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
                    borderSide: const BorderSide(color: Color(0xFF1F2D44)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1F2D44)),
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
              child: const Text(
                '취소',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: const Color(0xFF0D1421),
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
                      final idResult = await AuthService.findId(email: email);

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
                            title: const Text(
                              '찾기 실패',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            content: Text(
                              idResult['error'] ?? '해당 이메일로 가입된 계정을 찾을 수 없습니다.',
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  '확인',
                                  style: TextStyle(color: AppColors.textMuted),
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
                      );

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
                          title: const Text(
                            '계정 정보 확인',
                            style: TextStyle(
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
                                    const Text(
                                      '아이디',
                                      style: TextStyle(
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
                                      const Text(
                                        '비밀번호 재설정 완료',
                                        style: TextStyle(
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
                                        const Text(
                                          '보안을 위해 임시 비밀번호는 화면에 표시되지 않습니다.',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${pwResult['expiresInMinutes']}분 후 만료 · 로그인 후 반드시 변경해주세요',
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
                              child: const Text(
                                '확인',
                                style: TextStyle(color: AppColors.textMuted),
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
                        color: Color(0xFF0D1421),
                      ),
                    )
                  : const Text(
                      '찾기',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog() {
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '비밀번호 찾기',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '닉네임과 가입 이메일을 입력하면 임시 비밀번호를 발급합니다.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usernameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: '닉네임(아이디)',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1F2D44)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1F2D44)),
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
                hintText: '가입 이메일 (필수)',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1F2D44)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1F2D44)),
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
            child: const Text(
              '취소',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await AuthService.resetPassword(
                username: usernameCtrl.text.trim(),
                email: emailCtrl.text.trim(),
              );
              if (!mounted) return;
              Navigator.pop(context);
              final bool ok = result['success'] == true;
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.bgCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    ok ? '임시 비밀번호 발급' : '찾기 실패',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  content: Text(
                    ok
                        ? (kDebugMode
                              ? '임시 비밀번호: ${result['tempPassword']}\n'
                                    '${result['expiresInMinutes']}분 후 만료됩니다.\n'
                                    '로그인 후 반드시 변경해주세요.'
                              : '${result['expiresInMinutes']}분 후 만료됩니다.\n'
                                    '보안을 위해 임시 비밀번호는 화면에 표시되지 않습니다.\n'
                                    '로그인 후 반드시 변경해주세요.')
                        : (result['error'] ?? '오류가 발생했습니다.'),
                    style: TextStyle(
                      color: ok ? AppColors.teal : AppColors.error,
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('확인'),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
            child: const Text('발급', style: TextStyle(color: AppColors.bgDeep)),
          ),
        ],
      ),
    );
  }
}

// ── 회원가입 탭 ───────────────────────────────────────────────────────────────
class _SignupTab extends StatefulWidget {
  final Future<void> Function(Map<String, String>) onSignupSuccess;
  const _SignupTab({required this.onSignupSuccess});

  @override
  State<_SignupTab> createState() => _SignupTabState();
}

class _SignupTabState extends State<_SignupTab> {
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _socialCtrl = TextEditingController();

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
  bool _agreeLocation = false; // 동의 체크
  bool _locationGranted = false; // 실제 OS 권한 허용 여부

  // ── 이메일 인증 OTP 상태 ──
  bool _showOtpScreen = false; // OTP 입력 화면 표시 여부
  final _otpCtrl = TextEditingController();
  String? _otpError;
  String? _devOtpCode; // 개발용: 생성된 OTP 코드 (실제 배포시 제거)
  int _otpCountdown = 0; // 남은 시간 (초)
  Timer? _otpTimer; // 타이머

  // 가입 버튼 활성화 조건
  bool get _canSignUp => _agreePrivacy && !_isLoading;

  @override
  void initState() {
    super.initState();
    _loadOnboardingCountry();
    // 실시간 검증 리스너
    _usernameCtrl.addListener(_validateUsername);
    _passCtrl.addListener(_validatePassword);
  }

  Future<void> _loadOnboardingCountry() async {
    final data = await AuthService.getOnboardingCountry();
    if (mounted) {
      setState(() {
        _selectedCountry = data['country'] ?? '대한민국';
        _selectedFlag = data['countryFlag'] ?? '🇰🇷';
      });
    }
  }

  void _validateUsername() {
    final err = AuthService.validateUsername(_usernameCtrl.text);
    if (_usernameError != err) setState(() => _usernameError = err);
  }

  void _validatePassword() {
    final err = AuthService.validatePassword(_passCtrl.text);
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
    _otpCtrl.dispose();
    _otpTimer?.cancel();
    super.dispose();
  }

  /// Step 1: 폼 검증 후 OTP 발송 화면으로 전환
  Future<void> _signUp() async {
    if (!_agreePrivacy) {
      setState(() => _error = '개인정보 처리방침에 동의해야 가입할 수 있습니다.');
      return;
    }
    // 폼 기본 검증
    final emailVal = _emailCtrl.text.trim();
    if (emailVal.isEmpty) {
      setState(() => _error = '이메일을 입력해주세요.');
      return;
    }
    final emailErr = AuthService.validateEmail(emailVal);
    if (emailErr != null) {
      setState(() => _error = emailErr);
      return;
    }
    final taken = await AuthService.isEmailTaken(emailVal);
    if (taken) {
      setState(() => _error = '이미 가입된 이메일입니다.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // OTP 생성 (rate limit 초과 시 null 반환)
    final code = AuthService.generateEmailOtp(emailVal);

    if (!mounted) return;
    if (code == null) {
      final cooldown = AuthService.otpCooldownSecondsRemaining;
      setState(() {
        _isLoading = false;
        _error = cooldown > 0
            ? '잠시 후 다시 시도해주세요. (${cooldown}초 후 재시도 가능)'
            : '인증 코드 요청 횟수를 초과했습니다. 잠시 후 다시 시도해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _showOtpScreen = true;
      _devOtpCode = code; // 개발용 표시 (배포시 제거)
      _otpError = null;
      _otpCountdown = AuthService.otpRemainingSeconds;
    });
    _startOtpTimer();
  }

  /// Step 2: OTP 확인 후 실제 회원가입 완료
  Future<void> _verifyOtpAndComplete() async {
    final emailVal = _emailCtrl.text.trim();
    final otpVal = _otpCtrl.text.trim();

    if (otpVal.length != 6) {
      setState(() => _otpError = '6자리 코드를 입력해주세요.');
      return;
    }

    final otpErr = AuthService.verifyEmailOtp(emailVal, otpVal);
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
    );

    if (!mounted) return;

    if (err != null) {
      setState(() {
        _isLoading = false;
        _otpError = err;
      });
      return;
    }

    final user = await AuthService.getCurrentUser();
    if (user != null) await widget.onSignupSuccess(user);
  }

  /// OTP 재발송
  void _resendOtp() {
    _otpTimer?.cancel();
    final emailVal = _emailCtrl.text.trim();
    final code = AuthService.generateEmailOtp(emailVal);
    if (code == null) {
      final cooldown = AuthService.otpCooldownSecondsRemaining;
      setState(() {
        _otpError = cooldown > 0
            ? '${cooldown}초 후 재발송 가능합니다.'
            : '인증 코드 요청 횟수를 초과했습니다. 잠시 후 다시 시도해주세요.';
      });
      return;
    }
    setState(() {
      _otpCtrl.clear();
      _otpError = null;
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
    setState(() {
      _agreeLocation =
          granted || permission == LocationPermission.deniedForever;
      _locationGranted = granted;
    });
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('위치 권한이 거부되었습니다.\n설정 → 앱 → 위치에서 허용해주세요.'),
          backgroundColor: AppColors.bgCard,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: '설정 열기',
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
    return _buildSignupForm(context);
  }

  Widget _buildSignupForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) _ErrorBanner(message: _error!),

          // ── 1. 이메일 ──────────────────────────────────────────────────────
          _InputField(
            controller: _emailCtrl,
            label: '이메일',
            hint: 'example@email.com',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),

          // ── 2. 아이디 ──────────────────────────────────────────────────────
          _InputField(
            controller: _usernameCtrl,
            label: '아이디',
            hint: 'traveler42   (영문 시작, 영문·숫자·_ 2~20자)',
            icon: Icons.person_rounded,
          ),
          if (_usernameError != null)
            _FieldError(message: _usernameError!)
          else if (_usernameTaken)
            _FieldError(message: '이미 사용 중인 아이디입니다. 다른 아이디를 입력해주세요.'),
          const SizedBox(height: 12),

          // ── 3. 비밀번호 ────────────────────────────────────────────────────
          _InputField(
            controller: _passCtrl,
            label: '비밀번호',
            hint: 'Pass123   (영문+숫자 포함 6~12자)',
            icon: Icons.lock_rounded,
            obscureText: _obscurePass,
            suffixIcon: IconButton(
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
                border: Border.all(color: const Color(0xFF1F2D44)),
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
                        const Text(
                          '거주 국가',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          _selectedCountry,
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
            label: 'SNS 링크 (선택)',
            hint: 'https://instagram.com/...',
            icon: Icons.link_rounded,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 20),

          // ── 6. 개인정보 동의 ───────────────────────────────────────────────
          _ConsentCard(
            checked: _agreePrivacy,
            icon: Icons.shield_outlined,
            iconColor: AppColors.teal,
            title: '(필수) 개인정보 처리방침',
            linkLabel: '내용 보기',
            description: '수집 항목: 이메일·닉네임·국가·위치(도시 단위)\n목적: 서비스 제공, 계정 관리',
            onCheckChanged: (v) => setState(() => _agreePrivacy = v ?? false),
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
            title: '(선택) 현재 위치 사용 동의',
            description:
                '가입 후 편지 발송 시점에도 위치 권한을 요청할 수 있어요.\n'
                '지금 동의하면 위치 기반 기능을 바로 사용할 수 있습니다.',
            statusWidget: _locationGranted
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.teal,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '허용됨',
                        style: TextStyle(color: AppColors.teal, fontSize: 11),
                      ),
                    ],
                  )
                : null,
            onCheckChanged: _onLocationConsentTap,
          ),
          const SizedBox(height: 24),

          // ── 가입하기 버튼 ─────────────────────────────────────────────────
          _AuthButton(
            label: '가입하기',
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
                  '이메일 입력으로 돌아가기',
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
                  child: Icon(
                    Icons.mark_email_read_rounded,
                    size: 32,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '이메일 인증',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$email\n으로 인증 코드를 발송했습니다.',
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

          // 개발용: OTP 코드 표시 (배포 시 이 블록 제거)
          if (kDebugMode && _devOtpCode != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8A5C).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFF8A5C).withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    '[개발용] 실제 배포 시 이 박스는 제거됩니다.',
                    style: TextStyle(color: Color(0xFFFF8A5C), fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '인증 코드: $_devOtpCode',
                    style: const TextStyle(
                      color: Color(0xFFFF8A5C),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
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
            onChanged: (_) {
              if (_otpError != null) setState(() => _otpError = null);
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
                  '${(_otpCountdown ~/ 60).toString().padLeft(2, '0')}:${(_otpCountdown % 60).toString().padLeft(2, '0')} 후 만료',
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
                  expired ? '코드 재발송' : '재발송',
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
          const SizedBox(height: 32),

          // 확인 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading || expired ? null : _verifyOtpAndComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.bgCard,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      '인증 완료 · 가입하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),

          if (expired) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                '인증 코드가 만료되었습니다. 재발송을 눌러주세요.',
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '개인정보 처리방침',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '1. 수집 항목',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '이메일, 닉네임, 국가, SNS 링크(선택)',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                '2. 수집 목적',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '서비스 제공, 편지 발송 및 수신, 계정 관리',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                '3. 보유 기간',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '회원 탈퇴 시까지 (탈퇴 즉시 모든 데이터 삭제)',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                '4. 제3자 제공',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '수집된 개인정보는 제3자에게 제공되지 않습니다.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
            child: const Text(
              '동의하기',
              style: TextStyle(color: AppColors.bgDeep),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '닫기',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  void _pickCountry() {
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '거주 국가 선택',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
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
                    const Expanded(
                      child: Text(
                        '선택한 나라의 언어로 앱이 표시됩니다',
                        style: TextStyle(
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
                        c['name']!,
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
                          _selectedCountry = c['name']!;
                          _selectedFlag = c['flag']!;
                        });
                        Navigator.pop(ctx);
                        // 언어 안내 스낵바
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🌐 언어가 $langName(으)로 설정됩니다'),
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
          borderSide: const BorderSide(color: Color(0xFF1F2D44)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1F2D44)),
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
        style: ElevatedButton.styleFrom(
          backgroundColor: active
              ? AppColors.gold
              : AppColors.gold.withValues(alpha: 0.3),
          foregroundColor: AppColors.bgDeep,
          disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
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
    this.linkLabel,
    this.statusWidget,
    this.onCheckChanged,
    this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: checked
            ? AppColors.teal.withValues(alpha: 0.07)
            : AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: checked
              ? AppColors.teal.withValues(alpha: 0.4)
              : const Color(0xFF1F2D44),
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
                  '동의합니다',
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
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.04);
    final rng = Random(99);
    for (int i = 0; i < 60; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        rng.nextDouble() * 1.5 + 0.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
