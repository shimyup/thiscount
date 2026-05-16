// Build 284: 새 온보딩 투어 화면 — 첫 진입 시 1회 노출.
//
// 의도: 기존 [OnboardingScreen] (1329 LOC, country / location / premium 흐름)
// 앞에 **개념 / 사용법 / 등급 차이 / 게임 / Brand ROI** 를 빠르게 보여주는
// 인포그래픽 투어. PageView 의 default physics (swipe + drag) — 자동 timer
// 없음. 사용자가 자유롭게 swipe 또는 indicator 클릭으로 페이지 이동.
//
// 라우팅: 최초 1회 (`SharedPreferences seen_onboarding_tour != true`) 만
// 표시. "시작" 버튼 → /onboarding (기존 흐름).

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_palette.dart';

class OnboardingTourScreen extends StatefulWidget {
  const OnboardingTourScreen({super.key});

  static const String routeName = '/onboarding_tour';

  /// 처음 진입 시 [SharedPreferences] 에 마킹.
  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding_tour', true);
  }

  /// 다음 라우트 결정 헬퍼. 처음이면 tour, 아니면 기존 onboarding.
  static Future<String> nextRouteAfterSplash() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seen_onboarding_tour') ?? false;
    return seen ? '/onboarding' : routeName;
  }

  @override
  State<OnboardingTourScreen> createState() => _OnboardingTourScreenState();
}

class _OnboardingTourScreenState extends State<OnboardingTourScreen> {
  final PageController _ctrl = PageController();
  int _page = 0;

  // 5 페이지 + 마지막 CTA — 사용자 swipe 자유, 자동 timer 없음.
  static const int _totalPages = 6;

  void _next() {
    if (_page < _totalPages - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _start();
    }
  }

  Future<void> _start() async {
    await OnboardingTourScreen.markSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/onboarding');
  }

  Future<void> _skip() async {
    await OnboardingTourScreen.markSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/onboarding');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = const AppPaletteDark(); // tour 는 항상 dark 무드 (브랜드 baseline)
    return Scaffold(
      backgroundColor: p.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            // ── 상단: Skip ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_page < _totalPages - 1)
                    TextButton(
                      onPressed: _skip,
                      child: Text(
                        '건너뛰기',
                        style: TextStyle(
                          color: p.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── PageView ────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _ctrl,
                // Build 287: 스크롤(swipe) 로 한장씩 넘김 명시.
                physics: const PageScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: const [
                  _WelcomePage(),
                  _PickupHowToPage(),
                  _TierComparePage(),
                  _GameGrowthPage(),
                  _BrandRoiPage(),
                  _ReadyPage(),
                ],
              ),
            ),

            // ── 페이지 indicator ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (i) {
                  final active = i == _page;
                  return GestureDetector(
                    onTap: () => _ctrl.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOut,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? p.premium : p.bgElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── CTA ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.premium,
                    foregroundColor: p.premiumInk,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _page < _totalPages - 1 ? '다음' : '시작하기',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
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
}

// ─────────────────────────────────────────────────────────────────
// Page 1 — Welcome
// ─────────────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();
  @override
  Widget build(BuildContext context) {
    const p = AppPaletteDark();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _Eyebrow(text: '01 · 컨셉'),
          const SizedBox(height: 16),
          const Text(
            '걸어가다\n줍는 디스카운트',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '근처에 떠있는 쿠폰과 혜택을\n주워 쓰는 위치 기반 지갑.',
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.45,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 36),
          // 큰 가시화 — 핀 + 사용자 + 반경
          Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 100m radius ring
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: p.premium.withOpacity(.3), width: 2),
                    ),
                  ),
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.premium.withOpacity(.06),
                    ),
                  ),
                  // 카테고리 핀 4개
                  const _Pin(top: 30, left: 60, color: 0xFFFF4D6D),
                  const _Pin(top: 60, left: 180, color: 0xFFB8FF5C),
                  const _Pin(top: 160, left: 50, color: 0xFF5BA4F6),
                  const _Pin(top: 175, left: 175, color: 0xFFC77DFF),
                  // 사용자 (중앙, 큰 골드)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.premium,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: p.premium.withOpacity(.5),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
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
}

// ─────────────────────────────────────────────────────────────────
// Page 2 — Pickup How-To (4 단계 인포그래픽)
// ─────────────────────────────────────────────────────────────────

class _PickupHowToPage extends StatelessWidget {
  const _PickupHowToPage();

  @override
  Widget build(BuildContext context) {
    const p = AppPaletteDark();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(text: '02 · 사용법'),
          const SizedBox(height: 14),
          const Text(
            '메시지 줍는 4단계',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '걷기만 해도 자동으로 도착해요.',
            style: TextStyle(color: p.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 24),
          const _StepRow(
            number: 1,
            emoji: '🗺',
            title: '지도 열기',
            desc: '근처에 떠있는 핀들이 카테고리 색으로 표시돼요',
            accent: 0xFF5BA4F6,
          ),
          const _StepRow(
            number: 2,
            emoji: '🎯',
            title: '가까이 가기',
            desc: '내 반경 100m (Premium 1km) 안의 핀이 활성화',
            accent: 0xFFFFD60A,
          ),
          const _StepRow(
            number: 3,
            emoji: '🤲',
            title: '탭해서 줍기',
            desc: '한 번의 탭으로 인박스에 자동 저장. 광역 발견감!',
            accent: 0xFFFF4D6D,
          ),
          const _StepRow(
            number: 4,
            emoji: '🎟',
            title: '매장에서 사용',
            desc: 'QR/코드를 직원에게 보여주면 즉시 할인 적용',
            accent: 0xFFB8FF5C,
            last: true,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Page 3 — Tier Compare (Free / Premium / Brand 비교 표)
// ─────────────────────────────────────────────────────────────────

class _TierComparePage extends StatelessWidget {
  const _TierComparePage();

  @override
  Widget build(BuildContext context) {
    const p = AppPaletteDark();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _Eyebrow(text: '03 · 등급별 차이'),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '등급마다\n할 수 있는 게 달라요',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _TierCard(
            tier: 'Free',
            tagline: '동네 헌터',
            color: 0xFF8E8E93,
            features: const [
              '📍 픽업 반경 200m + 레벨당 10m',
              '✉️  편지 보내기 (일반)',
              '🎯 ExactDrop 사용 불가',
              '🎮 매일 XP 획득 + 레벨업',
            ],
          ),
          const SizedBox(height: 12),
          _TierCard(
            tier: 'Premium',
            tagline: '광역 마스터',
            color: 0xFFFFD60A,
            featured: true,
            features: const [
              '📍 픽업 반경 **1km** + 레벨당 10m',
              '🎯 정확 좌표 발송 (ExactDrop)',
              '🖼  사진 첨부 가능',
              '🔔 가까운 핀 푸시 알림',
            ],
          ),
          const SizedBox(height: 12),
          _TierCard(
            tier: 'Brand',
            tagline: '캠페인 발신자',
            color: 0xFFFF4D6D,
            features: const [
              '🏪 매장 위치 자동 발급 zone',
              '🎟 쿠폰 / 교환권 발송',
              '📊 픽업률 / 사용률 대시보드',
              '🌊 대량 발송 + 산업군 타게팅',
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.hairline),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '신규 가입 7일 Premium 무료 체험\n언제든 해지 가능',
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Page 4 — Game Growth (XP / 레벨 / 칭호)
// ─────────────────────────────────────────────────────────────────

class _GameGrowthPage extends StatelessWidget {
  const _GameGrowthPage();
  @override
  Widget build(BuildContext context) {
    const p = AppPaletteDark();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(text: '04 · 게임 성장'),
          const SizedBox(height: 14),
          const Text(
            '줍을수록\n반경이 커져요',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'XP → 레벨 → 칭호. 매일 픽업/발송으로 성장.',
            style: TextStyle(color: p.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 22),
          // XP 분배
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: p.bgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.hairline),
            ),
            child: const Column(
              children: [
                _XpRow(label: '🤲 픽업', value: '+10 XP', emoji: '·'),
                SizedBox(height: 10),
                _XpRow(label: '✉️ 발송', value: '+5 XP', emoji: '·'),
                SizedBox(height: 10),
                _XpRow(label: '📍 픽업 거리', value: '+0.1 XP / km', emoji: '·'),
                SizedBox(height: 10),
                _XpRow(label: '🛩 발송 거리', value: '+0.05 XP / km', emoji: '·'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // 칭호 계단
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: p.bgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.hairline),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '칭호 9단계',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 12),
                _TitleStep(level: 1, name: '새내기 탐험가', emoji: '🎟', accent: 0xFF8E8E93),
                _TitleStep(level: 5, name: '초보 헌터', emoji: '🎫', accent: 0xFFB8FF5C),
                _TitleStep(level: 15, name: '마을 쇼핑러', emoji: '🛍', accent: 0xFF5BA4F6),
                _TitleStep(level: 30, name: '혜택 마스터', emoji: '🏆', accent: 0xFFFFD60A),
                _TitleStep(level: 50, name: '전설의 혜택 헌터', emoji: '👑', accent: 0xFFC77DFF, last: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Page 5 — Brand ROI (발송 → 픽업 → 사용 funnel)
// ─────────────────────────────────────────────────────────────────

class _BrandRoiPage extends StatelessWidget {
  const _BrandRoiPage();
  @override
  Widget build(BuildContext context) {
    const p = AppPaletteDark();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(text: '05 · Brand ROI'),
          const SizedBox(height: 14),
          const Text(
            'Brand 만의\n실시간 분석',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '발송한 쿠폰의 픽업·사용까지 한눈에.',
            style: TextStyle(color: p.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          // Funnel
          const _FunnelBar(
            label: '🌊 발송',
            value: '1,000통',
            ratio: '100%',
            color: 0xFFFF4D6D,
            width: 1.0,
          ),
          const SizedBox(height: 10),
          const _FunnelBar(
            label: '🤲 픽업',
            value: '320통',
            ratio: '32%',
            color: 0xFFFFD60A,
            width: 0.32,
          ),
          const SizedBox(height: 10),
          const _FunnelBar(
            label: '🎟 사용',
            value: '180통',
            ratio: '18% (CR 56%)',
            color: 0xFFB8FF5C,
            width: 0.18,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.hairline),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RoiKpi(label: '평균 픽업 거리', value: '480m', emoji: '📍'),
                SizedBox(height: 10),
                _RoiKpi(label: '평균 사용까지 시간', value: '4시간 22분', emoji: '⏱'),
                SizedBox(height: 10),
                _RoiKpi(label: 'CSV 내보내기', value: '실시간', emoji: '📊'),
                SizedBox(height: 10),
                _RoiKpi(label: '자동 발급 zone', value: '매장 반경 50m–5km', emoji: '🏪'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Page 6 — Ready CTA
// ─────────────────────────────────────────────────────────────────

class _ReadyPage extends StatelessWidget {
  const _ReadyPage();
  @override
  Widget build(BuildContext context) {
    const p = AppPaletteDark();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          // 큰 핀 (Icon A-refined 와 유사)
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.premium,
              boxShadow: [
                BoxShadow(
                  color: p.premium.withOpacity(.4),
                  blurRadius: 60,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '%',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1300),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '지금, 근처에\n뜨고 있어요',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '7일 무료 Premium 체험과 함께\n시작해 보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 공통 UI 헬퍼
// ─────────────────────────────────────────────────────────────────

class _Eyebrow extends StatelessWidget {
  final String text;
  const _Eyebrow({required this.text});
  @override
  Widget build(BuildContext context) {
    const p = AppPaletteDark();
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: p.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  final double top;
  final double left;
  final int color;
  const _Pin({required this.top, required this.left, required this.color});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(color),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: Color(color).withOpacity(.45), blurRadius: 14),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int number;
  final String emoji;
  final String title;
  final String desc;
  final int accent;
  final bool last;
  const _StepRow({
    required this.number,
    required this.emoji,
    required this.title,
    required this.desc,
    required this.accent,
    this.last = false,
  });
  @override
  Widget build(BuildContext context) {
    const p = AppPaletteDark();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 좌측 number + line
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(accent),
                  boxShadow: [
                    BoxShadow(
                      color: Color(accent).withOpacity(.35),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Color(0xFF101010),
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: p.hairline,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // 본문
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 24, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: 14,
                      height: 1.45,
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
}

class _TierCard extends StatelessWidget {
  final String tier;
  final String tagline;
  final int color;
  final List<String> features;
  final bool featured;
  const _TierCard({
    required this.tier,
    required this.tagline,
    required this.color,
    required this.features,
    this.featured = false,
  });
  @override
  Widget build(BuildContext context) {
    const p = AppPaletteDark();
    return Container(
      decoration: BoxDecoration(
        color: p.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: featured ? Color(color) : p.hairline,
          width: featured ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Color(color),
              child: Row(
                children: [
                  Text(
                    tier,
                    style: const TextStyle(
                      color: Color(0xFF101010),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tagline,
                    style: const TextStyle(
                      color: Color(0xFF101010),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (featured) const Spacer(),
                  if (featured)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        '추천',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: features
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          f.replaceAll('**', ''),
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _XpRow extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  const _XpRow({required this.label, required this.value, required this.emoji});
  @override
  Widget build(BuildContext context) {
    const p = AppPaletteDark();
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFB8FF5C),
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _TitleStep extends StatelessWidget {
  final int level;
  final String name;
  final String emoji;
  final int accent;
  final bool last;
  const _TitleStep({
    required this.level,
    required this.name,
    required this.emoji,
    required this.accent,
    this.last = false,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(accent).withOpacity(.2),
              border: Border.all(color: Color(accent), width: 1.5),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Lv $level',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FunnelBar extends StatelessWidget {
  final String label;
  final String value;
  final String ratio;
  final int color;
  final double width; // 0..1
  const _FunnelBar({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
    required this.width,
  });
  @override
  Widget build(BuildContext context) {
    const p = AppPaletteDark();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$value · $ratio',
              style: TextStyle(
                color: p.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 14,
              decoration: BoxDecoration(
                color: p.bgCard,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            FractionallySizedBox(
              widthFactor: width.clamp(0.05, 1.0),
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: Color(color),
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: [
                    BoxShadow(color: Color(color).withOpacity(.4), blurRadius: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoiKpi extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  const _RoiKpi({required this.label, required this.value, required this.emoji});
  @override
  Widget build(BuildContext context) {
    const p = AppPaletteDark();
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
