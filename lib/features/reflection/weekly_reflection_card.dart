import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import 'weekly_reflection.dart';

/// Shown on the profile screen on Sundays only. Summarizes the user's
/// letter-writing week with 3 stats + a short greeting. Dismissible via
/// a pref that resets every Monday (i.e. you see it once per week max).
///
/// Why Sunday only: ISO week ends Sunday night (week spans Mon–Sun), so
/// showing it earlier would be a preview, not a summary. A full Wrapped
/// moment at week's end is more resonant than a mid-week progress bar.
class WeeklyReflectionCard extends StatefulWidget {
  const WeeklyReflectionCard({super.key});

  @override
  State<WeeklyReflectionCard> createState() => _WeeklyReflectionCardState();
}

class _WeeklyReflectionCardState extends State<WeeklyReflectionCard> {
  bool _loading = true;
  bool _dismissed = false;
  String _weekKey = '';

  @override
  void initState() {
    super.initState();
    _weekKey = _currentWeekKey();
    _loadDismissed();
  }

  String _currentWeekKey() {
    final now = DateTime.now();
    // yyyy-Wnn to match dismissal scope (one card per ISO week)
    final thursday = now.add(Duration(days: 4 - now.weekday));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final firstWeek =
        firstThursday.subtract(Duration(days: firstThursday.weekday - 1));
    final weekNumber =
        1 + (thursday.difference(firstWeek).inDays / 7).floor();
    return '${thursday.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final d = prefs.getString('weekly_reflection_dismissed') ?? '';
    if (mounted) {
      setState(() {
        _dismissed = d == _weekKey;
        _loading = false;
      });
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weekly_reflection_dismissed', _weekKey);
    if (mounted) setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_dismissed) return const SizedBox.shrink();
    // 일요일 (weekday=7)만 노출 — 주가 끝나는 시점의 진짜 회고
    if (DateTime.now().weekday != DateTime.sunday) {
      return const SizedBox.shrink();
    }
    return Consumer<AppState>(
      builder: (context, state, _) {
        final reflection = WeeklyReflection.compute(state.sent);
        if (reflection.isEmpty) return const SizedBox.shrink();
        final l10n = AppL10n.of(state.currentUser.languageCode);
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gold.withValues(alpha: 0.18),
                AppColors.teal.withValues(alpha: 0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🗓️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.weeklyReflectionTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _dismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l10n.weeklyReflectionSummary(
                  reflection.letterCount,
                  reflection.uniqueCountries,
                  reflection.uniqueContinents,
                ),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              if (reflection.longestKm > 100) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.weeklyReflectionLongest(
                    reflection.longestKm.round(),
                  ),
                  style: TextStyle(
                    color: AppColors.gold.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
