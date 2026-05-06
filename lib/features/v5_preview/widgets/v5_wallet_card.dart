import 'package:flutter/material.dart';
import '../theme/v5_tokens.dart';

class V5WalletCard extends StatelessWidget {
  final V5Category category;
  final String brand;
  final String title;
  final String? sub;
  final String? deadline;
  final bool urgent;
  final int? stampsTotal;
  final int? stampsFilled;
  final VoidCallback? onTap;

  const V5WalletCard({
    super.key,
    required this.category,
    required this.brand,
    required this.title,
    this.sub,
    this.deadline,
    this.urgent = false,
    this.stampsTotal,
    this.stampsFilled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = category.ink;
    final hasStamps = stampsTotal != null && stampsFilled != null;

    return Material(
      color: category.bg,
      borderRadius: BorderRadius.circular(V5Radius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      brand.toUpperCase(),
                      style: V5Text.brandLine.copyWith(
                        color: ink.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  if (deadline != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: urgent
                            ? V5Colors.bg
                            : ink.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(V5Radius.chip),
                      ),
                      child: Text(
                        deadline!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                          color: urgent ? Colors.white : ink,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: V5Text.cardTitle.copyWith(color: ink),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (sub != null) ...[
                const SizedBox(height: 2),
                Text(
                  sub!,
                  style: V5Text.meta.copyWith(
                    color: ink.withValues(alpha: 0.65),
                    fontSize: 13,
                  ),
                ),
              ],
              if (hasStamps) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: ink.withValues(alpha: 0.16),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '도장',
                        style: V5Text.meta.copyWith(
                          color: ink.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(V5Radius.chip),
                          child: LinearProgressIndicator(
                            value: stampsFilled! / stampsTotal!,
                            minHeight: 4,
                            backgroundColor: ink.withValues(alpha: 0.18),
                            valueColor: AlwaysStoppedAnimation(ink),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$stampsFilled / $stampsTotal',
                        style: V5Text.meta.copyWith(
                          color: ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
