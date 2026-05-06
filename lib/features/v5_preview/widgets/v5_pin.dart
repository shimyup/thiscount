import 'package:flutter/material.dart';
import '../theme/v5_tokens.dart';

class V5Pin extends StatelessWidget {
  final V5Category category;
  final bool selected;

  const V5Pin({super.key, required this.category, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final size = selected ? 22.0 : 14.0;
    final border = selected ? 4.0 : 3.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: category.bg,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF050608), width: border),
        boxShadow: [
          BoxShadow(
            color: selected
                ? category.bg.withValues(alpha: 0.6)
                : Colors.black.withValues(alpha: 0.6),
            blurRadius: selected ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

class V5ClusterPin extends StatelessWidget {
  final int count;
  final List<V5Category> categories;

  const V5ClusterPin({
    super.key,
    required this.count,
    this.categories = const [V5Category.coupon, V5Category.letter],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 5, 10, 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...categories.take(2).map(
            (c) => Container(
              margin: const EdgeInsets.only(right: 1),
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: c.bg, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class V5UserPin extends StatelessWidget {
  const V5UserPin({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: V5Colors.map,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF050608), width: 3),
        boxShadow: [
          BoxShadow(
            color: V5Colors.map.withValues(alpha: 0.6),
            blurRadius: 16,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: V5Colors.map.withValues(alpha: 0.12),
            blurRadius: 0,
            spreadRadius: 8,
          ),
        ],
      ),
    );
  }
}
