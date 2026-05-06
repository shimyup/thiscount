import 'package:flutter/material.dart';
import '../theme/v5_tokens.dart';

class V5ProfileScreen extends StatelessWidget {
  final VoidCallback onPremiumTap;

  const V5ProfileScreen({super.key, required this.onPremiumTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V5Colors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            Text('나.', style: V5Text.display.copyWith(fontSize: 34)),
            const SizedBox(height: 18),
            _passCard(),
            const SizedBox(height: 14),
            _menuList(),
          ],
        ),
      ),
    );
  }

  Widget _passCard() {
    const ink = V5Colors.premiumInk;
    return GestureDetector(
      onTap: onPremiumTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: V5Colors.premium,
          borderRadius: BorderRadius.circular(24),
          boxShadow: V5Shadow.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AIR MAIL · PREMIUM',
                  style: V5Text.brandLine.copyWith(
                    color: ink.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  'SEQ 0421',
                  style: V5Text.mono.copyWith(
                    color: ink.withValues(alpha: 0.6),
                    fontSize: 11,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'SHIM YUP',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: ink,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '@shimyup · since 04 · 2026',
              style: V5Text.meta.copyWith(
                color: ink.withValues(alpha: 0.65),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.only(top: 18),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: ink.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: _statCell('47', '픽업')),
                  Container(
                    width: 1,
                    height: 36,
                    color: ink.withValues(alpha: 0.14),
                  ),
                  Expanded(child: _statCell('12', '발송')),
                  Container(
                    width: 1,
                    height: 36,
                    color: ink.withValues(alpha: 0.14),
                  ),
                  Expanded(child: _statCell('7d', '스트릭')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCell(String v, String k) {
    const ink = V5Colors.premiumInk;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            v,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: ink,
              letterSpacing: -0.7,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            k.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ink.withValues(alpha: 0.6),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuList() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: V5Colors.bg2,
        borderRadius: BorderRadius.circular(V5Radius.tile),
      ),
      child: Column(
        children: [
          _menuItem(Icons.collections_bookmark_outlined, '도장 앨범', meta: '5 / 10'),
          _menuDivider(),
          _menuItem(Icons.card_giftcard_outlined, '받은 선물', meta: '3'),
          _menuDivider(),
          _menuItem(Icons.share_outlined, '공유 카드 만들기'),
          _menuDivider(),
          _menuItem(Icons.notifications_outlined, '알림 · 위치'),
          _menuDivider(),
          _menuItem(Icons.settings_outlined, '설정'),
        ],
      ),
    );
  }

  Widget _menuDivider() => Container(
    height: 0.5,
    color: V5Colors.hairline,
    margin: const EdgeInsets.symmetric(horizontal: 0),
  );

  Widget _menuItem(IconData icon, String label, {String? meta}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: V5Colors.bg3,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: V5Colors.tx, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: V5Text.meta.copyWith(
                color: V5Colors.tx,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (meta != null) ...[
            Text(
              meta,
              style: V5Text.meta.copyWith(
                color: V5Colors.tx2,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
          ],
          const Icon(Icons.chevron_right, color: V5Colors.tx3, size: 18),
        ],
      ),
    );
  }
}
