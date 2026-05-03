import 'package:flutter/material.dart';
import '../theme/v5_tokens.dart';
import '../widgets/v5_dev_bar.dart';
import 'v5_map.dart';
import 'v5_inbox.dart';
import 'v5_tower.dart';
import 'v5_profile.dart';

class V5MainScaffold extends StatefulWidget {
  final VoidCallback onCardTap;
  final VoidCallback onPremiumTap;
  final void Function(String) onDevJump;
  final int initialIndex;

  const V5MainScaffold({
    super.key,
    required this.onCardTap,
    required this.onPremiumTap,
    required this.onDevJump,
    this.initialIndex = 0,
  });

  @override
  State<V5MainScaffold> createState() => _V5MainScaffoldState();
}

class _V5MainScaffoldState extends State<V5MainScaffold> {
  late int _idx = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final pages = [
      V5MapScreen(onCardTap: widget.onCardTap),
      V5InboxScreen(onCardTap: widget.onCardTap),
      const V5TowerScreen(),
      V5ProfileScreen(onPremiumTap: widget.onPremiumTap),
    ];

    return Scaffold(
      backgroundColor: V5Colors.bg,
      body: Stack(
        children: [
          Column(
            children: [
              V5DevBar(current: 'main', onJump: widget.onDevJump),
              Expanded(child: pages[_idx]),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _tabBar(),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
      decoration: BoxDecoration(
        color: V5Colors.bg1.withValues(alpha: 0.94),
        border: const Border(
          top: BorderSide(color: V5Colors.hairline, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _tab(0, Icons.location_on_outlined, '지도'),
          _tab(1, Icons.account_balance_wallet_outlined, '지갑', badge: 5),
          _tab(2, Icons.workspace_premium_outlined, '카운터'),
          _tab(3, Icons.person_outline, '나'),
        ],
      ),
    );
  }

  Widget _tab(int i, IconData icon, String label, {int? badge}) {
    final on = i == _idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _idx = i),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: on ? V5Colors.tx : V5Colors.tx3,
                    size: 22,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: on ? V5Colors.tx : V5Colors.tx3,
                      letterSpacing: 0.04,
                    ),
                  ),
                ],
              ),
              if (badge != null)
                Positioned(
                  top: 2,
                  right: 24,
                  child: Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: V5Colors.coupon,
                      shape: BoxShape.circle,
                      border: Border.all(color: V5Colors.bg, width: 1.5),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
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
