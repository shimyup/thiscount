import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/config/firebase_config.dart';
import '../../core/services/firestore_service.dart';
import '../../state/app_state.dart';

// ── 회원 데이터 모델 ────────────────────────────────────────────────────────────
class AdminUser {
  final String id;
  final String username;
  final String country;
  final String countryFlag;
  final double latitude;
  final double longitude;
  final int receivedCount;
  final int replyCount;
  final int sentCount;
  final int likeCount;
  final int ratingTotal;
  final int ratingCount;
  final String inviteCode;
  final int inviteRewardCredits;
  final String updatedAt;
  final bool isBanned;
  final bool isPremium;
  final bool isBrand;
  final String? customTowerName;

  const AdminUser({
    required this.id,
    required this.username,
    required this.country,
    required this.countryFlag,
    required this.latitude,
    required this.longitude,
    this.receivedCount = 0,
    this.replyCount = 0,
    this.sentCount = 0,
    this.likeCount = 0,
    this.ratingTotal = 0,
    this.ratingCount = 0,
    this.inviteCode = '',
    this.inviteRewardCredits = 0,
    this.updatedAt = '',
    this.isBanned = false,
    this.isPremium = false,
    this.isBrand = false,
    this.customTowerName,
  });

  double get towerHeight =>
      (receivedCount * 1.2) +
      (likeCount * 2.0) +
      (replyCount * 1.5) +
      (sentCount * 0.8);

  double get avgRating => ratingCount > 0 ? ratingTotal / ratingCount : 0.0;

  String get tierEmoji {
    final h = towerHeight;
    if (h < 6) return '🛖';
    if (h < 15) return '🏠';
    if (h < 30) return '🏡';
    if (h < 50) return '🏘️';
    if (h < 80) return '🏢';
    if (h < 120) return '🏣';
    if (h < 170) return '🏙️';
    if (h < 250) return '🌆';
    if (h < 330) return '🌇';
    return '🗼';
  }

  factory AdminUser.fromFirestoreFields(
    String docId,
    Map<String, dynamic> fields,
  ) {
    String str(String key, [String fallback = '']) {
      final f = fields[key];
      if (f == null) return fallback;
      return (f as Map<String, dynamic>)['stringValue']?.toString() ?? fallback;
    }

    int intVal(String key) {
      final f = fields[key];
      if (f == null) return 0;
      final v = f as Map<String, dynamic>;
      return int.tryParse(v['integerValue']?.toString() ?? '') ?? 0;
    }

    double dblVal(String key) {
      final f = fields[key];
      if (f == null) return 0.0;
      final v = f as Map<String, dynamic>;
      return (v['doubleValue'] as num?)?.toDouble() ??
          double.tryParse(v['integerValue']?.toString() ?? '') ??
          0.0;
    }

    bool boolVal(String key) {
      final f = fields[key];
      if (f == null) return false;
      final v = f as Map<String, dynamic>;
      final raw = v['booleanValue'];
      if (raw is bool) return raw;
      if (raw is String) return raw.toLowerCase() == 'true';
      return false;
    }

    final id = str('id').isNotEmpty ? str('id') : docId;

    return AdminUser(
      id: id,
      username: str('username', '(No Name)'),
      country: str('country', 'Unknown'),
      countryFlag: str('countryFlag', '🌐'),
      latitude: dblVal('latitude'),
      longitude: dblVal('longitude'),
      receivedCount: intVal('receivedCount'),
      replyCount: intVal('replyCount'),
      sentCount: intVal('sentCount'),
      likeCount: intVal('likeCount'),
      ratingTotal: intVal('ratingTotal'),
      ratingCount: intVal('ratingCount'),
      inviteCode: str('inviteCode'),
      inviteRewardCredits: intVal('inviteRewardCredits'),
      updatedAt: str('updatedAt'),
      isBanned: boolVal('banned'),
      isPremium: boolVal('isPremium'),
      isBrand: boolVal('isBrand'),
      customTowerName: str('customTowerName').isEmpty
          ? null
          : str('customTowerName'),
    );
  }
}

// ── 회원 관리 화면 ──────────────────────────────────────────────────────────────
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<AdminUser> _users = [];
  List<AdminUser> _filtered = [];
  bool _loading = false;
  String? _error;
  final _searchCtrl = TextEditingController();
  String _sortBy = 'tower'; // tower | recent | sent

  AppL10n _l10n(BuildContext context) =>
      AppL10n.of(context.read<AppState>().currentUser.languageCode);

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilter);
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Firestore에서 전체 회원 불러오기 ────────────────────────────────────────
  Future<void> _fetchUsers() async {
    final l = _l10n(context);
    setState(() {
      _loading = true;
      _error = null;
    });

    if (!FirebaseConfig.kFirebaseEnabled) {
      setState(() {
        _loading = false;
        _error = l.koEn(
          'Firebase가 비활성화된 빌드입니다.\n--dart-define으로 Firebase 설정을 주입해주세요.',
          'Firebase is disabled in this build.\nInject Firebase config via --dart-define.',
        );
      });
      return;
    }

    try {
      final allUsers = <AdminUser>[];
      String? nextPageToken;
      int page = 0;

      do {
        page++;
        final params = [
          'key=${Uri.encodeQueryComponent(FirebaseConfig.apiKey)}',
          'pageSize=100',
          'mask.fieldPaths=id',
          'mask.fieldPaths=username',
          'mask.fieldPaths=country',
          'mask.fieldPaths=countryFlag',
          'mask.fieldPaths=latitude',
          'mask.fieldPaths=longitude',
          'mask.fieldPaths=receivedCount',
          'mask.fieldPaths=replyCount',
          'mask.fieldPaths=sentCount',
          'mask.fieldPaths=likeCount',
          'mask.fieldPaths=ratingTotal',
          'mask.fieldPaths=ratingCount',
          'mask.fieldPaths=inviteCode',
          'mask.fieldPaths=inviteRewardCredits',
          'mask.fieldPaths=updatedAt',
          'mask.fieldPaths=banned',
          'mask.fieldPaths=isPremium',
          'mask.fieldPaths=isBrand',
          'mask.fieldPaths=customTowerName',
        ];
        if (nextPageToken != null) {
          params.add('pageToken=${Uri.encodeQueryComponent(nextPageToken)}');
        }

        final url = Uri.parse(
          '${FirebaseConfig.firestoreBase}/users?${params.join('&')}',
        );
        final res = await http.get(url).timeout(const Duration(seconds: 10));
        if (res.statusCode != 200) {
          throw Exception('HTTP ${res.statusCode}');
        }

        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final docs = (body['documents'] as List?) ?? [];
        nextPageToken = body['nextPageToken'] as String?;

        for (final raw in docs.whereType<Map>()) {
          final doc = Map<String, dynamic>.from(raw);
          final fields = (doc['fields'] as Map<String, dynamic>?) ?? {};
          final docId = (doc['name'] as String? ?? '').split('/').last;
          if (docId.isNotEmpty) {
            allUsers.add(AdminUser.fromFirestoreFields(docId, fields));
          }
        }
      } while (nextPageToken != null && page < 5);

      _users = allUsers;
      _applySort();
    } catch (e) {
      setState(
        () => _error = l.koEn(
          '회원 정보를 불러오는 데 실패했어요.\n$e',
          'Failed to load user data.\n$e',
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = _users.where((u) {
        if (q.isEmpty) return true;
        return u.username.toLowerCase().contains(q) ||
            u.country.toLowerCase().contains(q) ||
            u.id.toLowerCase().contains(q);
      }).toList();
    });
  }

  void _applySort() {
    final list = List<AdminUser>.from(_users);
    switch (_sortBy) {
      case 'tower':
        list.sort((a, b) => b.towerHeight.compareTo(a.towerHeight));
        break;
      case 'recent':
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case 'sent':
        list.sort((a, b) => b.sentCount.compareTo(a.sentCount));
        break;
    }
    _users = list;
    _applyFilter();
  }

  // ── 차단/해제 ───────────────────────────────────────────────────────────────
  Future<void> _toggleBan(AdminUser user) async {
    final l = _l10n(context);
    final newBanned = !user.isBanned;
    final ok = await FirestoreService.setDocument('users/${user.id}', {
      'banned': newBanned,
    });
    if (!mounted) return;
    if (ok) {
      final idx = _users.indexWhere((u) => u.id == user.id);
      if (idx != -1) {
        _users[idx] = AdminUser(
          id: user.id,
          username: user.username,
          country: user.country,
          countryFlag: user.countryFlag,
          latitude: user.latitude,
          longitude: user.longitude,
          receivedCount: user.receivedCount,
          replyCount: user.replyCount,
          sentCount: user.sentCount,
          likeCount: user.likeCount,
          ratingTotal: user.ratingTotal,
          ratingCount: user.ratingCount,
          inviteCode: user.inviteCode,
          inviteRewardCredits: user.inviteRewardCredits,
          updatedAt: user.updatedAt,
          isBanned: newBanned,
          isPremium: user.isPremium,
          isBrand: user.isBrand,
          customTowerName: user.customTowerName,
        );
      }
      _applyFilter();
      _showSnack(
        newBanned
            ? l.koEn('🚫 차단됨: ${user.username}', '🚫 Banned: ${user.username}')
            : l.koEn(
                '✅ 차단 해제: ${user.username}',
                '✅ Unbanned: ${user.username}',
              ),
      );
    } else {
      _showSnack(
        l.koEn(
          '업데이트 실패. Firebase 권한을 확인하세요',
          'Update failed. Check Firebase permissions.',
        ),
        isError: true,
      );
    }
  }

  // ── 등급 승급/강등 ──────────────────────────────────────────────────────────
  Future<void> _setTier(AdminUser user, {required bool isPremium, required bool isBrand}) async {
    final l = _l10n(context);
    final ok = await FirestoreService.setDocument('users/${user.id}', {
      'isPremium': isPremium,
      'isBrand': isBrand,
    });
    if (!mounted) return;
    if (ok) {
      final idx = _users.indexWhere((u) => u.id == user.id);
      if (idx != -1) {
        _users[idx] = AdminUser(
          id: user.id,
          username: user.username,
          country: user.country,
          countryFlag: user.countryFlag,
          latitude: user.latitude,
          longitude: user.longitude,
          receivedCount: user.receivedCount,
          replyCount: user.replyCount,
          sentCount: user.sentCount,
          likeCount: user.likeCount,
          ratingTotal: user.ratingTotal,
          ratingCount: user.ratingCount,
          inviteCode: user.inviteCode,
          inviteRewardCredits: user.inviteRewardCredits,
          updatedAt: user.updatedAt,
          isBanned: user.isBanned,
          isPremium: isPremium,
          isBrand: isBrand,
          customTowerName: user.customTowerName,
        );
      }
      _applyFilter();
      final tierName = isBrand
          ? 'Brand'
          : isPremium
              ? 'Premium'
              : 'Free';
      _showSnack(
        l.koEn(
          '✅ ${user.username} → $tierName 변경 완료',
          '✅ ${user.username} → $tierName updated',
        ),
      );
    } else {
      _showSnack(
        l.koEn(
          '등급 변경 실패. Firebase 권한을 확인하세요',
          'Tier update failed. Check Firebase permissions.',
        ),
        isError: true,
      );
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError
            ? AppColors.error.withValues(alpha: 0.9)
            : AppColors.teal.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── 회원 상세 BottomSheet ───────────────────────────────────────────────────
  void _showUserDetail(AdminUser user) {
    final l = _l10n(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        builder: (_, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 핸들
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // 헤더
              Row(
                children: [
                  Text(user.countryFlag, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.username,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (user.isBrand) ...[
                              const SizedBox(width: 6),
                              _chip('Brand', AppColors.coupon),
                            ] else if (user.isPremium) ...[
                              const SizedBox(width: 6),
                              _chip('Premium', AppColors.gold),
                            ],
                            if (user.isBanned) ...[
                              const SizedBox(width: 6),
                              _chip(l.koEn('차단됨', 'Banned'), AppColors.error),
                            ],
                          ],
                        ),
                        Text(
                          '${user.country}  •  ${user.tierEmoji}  ${user.towerHeight.toStringAsFixed(1)}pt',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // ID
              _detailRow('ID', user.id, mono: true),
              if (user.customTowerName != null)
                _detailRow(
                  l.koEn('타워 이름', 'Tower Name'),
                  user.customTowerName!,
                ),
              if (user.inviteCode.isNotEmpty)
                _detailRow(l.koEn('초대 코드', 'Invite Code'), user.inviteCode),
              if (user.updatedAt.isNotEmpty)
                _detailRow(
                  l.koEn('마지막 활동', 'Last Active'),
                  user.updatedAt.length > 10
                      ? user.updatedAt.substring(0, 10)
                      : user.updatedAt,
                ),
              const SizedBox(height: 16),
              // 활동 통계
              _sectionLabel(l.koEn('활동 통계', 'Activity Stats')),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.8,
                children: [
                  _miniStat(
                    l.koEn('📥 받음', '📥 Received'),
                    '${user.receivedCount}',
                  ),
                  _miniStat(l.koEn('📤 발송', '📤 Sent'), '${user.sentCount}'),
                  _miniStat(
                    l.koEn('↩️ 답장', '↩️ Replies'),
                    '${user.replyCount}',
                  ),
                  _miniStat(l.koEn('❤️ 좋아요', '❤️ Likes'), '${user.likeCount}'),
                  _miniStat(
                    l.koEn('⭐ 별점', '⭐ Rating'),
                    user.avgRating > 0
                        ? user.avgRating.toStringAsFixed(1)
                        : '-',
                  ),
                  _miniStat(
                    l.koEn('🎁 크레딧', '🎁 Credits'),
                    '${user.inviteRewardCredits}',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 위치
              _sectionLabel(l.koEn('위치', 'Location')),
              _detailRow(
                l.koEn('좌표', 'Coordinates'),
                '${user.latitude.toStringAsFixed(4)}, ${user.longitude.toStringAsFixed(4)}',
              ),
              const SizedBox(height: 20),
              // ── 등급 변경 ──────────────────────────────────────────────
              _sectionLabel(l.koEn('등급 관리', 'Tier Management')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _tierButton(
                      label: 'Free',
                      emoji: '👤',
                      color: AppColors.textMuted,
                      isActive: !user.isPremium && !user.isBrand,
                      onTap: () {
                        Navigator.pop(ctx);
                        _setTier(user, isPremium: false, isBrand: false);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _tierButton(
                      label: 'Premium',
                      emoji: '⭐',
                      color: AppColors.gold,
                      isActive: user.isPremium && !user.isBrand,
                      onTap: () {
                        Navigator.pop(ctx);
                        _setTier(user, isPremium: true, isBrand: false);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _tierButton(
                      label: 'Brand',
                      emoji: '🏷️',
                      color: AppColors.coupon,
                      isActive: user.isBrand,
                      onTap: () {
                        Navigator.pop(ctx);
                        _setTier(user, isPremium: true, isBrand: true);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 차단/해제 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmToggleBan(user);
                  },
                  icon: Icon(
                    user.isBanned
                        ? Icons.lock_open_rounded
                        : Icons.block_rounded,
                    size: 18,
                  ),
                  label: Text(
                    user.isBanned
                        ? l.koEn('차단 해제', 'Unban')
                        : l.koEn('차단', 'Ban'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: user.isBanned
                        ? AppColors.teal
                        : AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 회원 삭제 버튼
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmDelete(user);
                  },
                  icon: const Icon(Icons.delete_forever_rounded, size: 18),
                  label: Text(l.koEn('회원 삭제', 'Delete User')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  // ── 회원 삭제 ───────────────────────────────────────────────────────────────
  //
  // Firestore 보안 규칙이 /users/{id} 삭제 시 `isSignedIn()` 을 요구하므로
  // API key 만으로는 401/403 으로 실패한다. FirestoreService.deleteDocument
  // 가 anonymous 인증 토큰을 Authorization 헤더에 자동으로 실어주므로,
  // 이쪽 경로로 호출한다. (차단/등급 변경은 이미 setDocument 를 쓰므로
  // 동일한 토큰 경로로 동작 중이다.)
  Future<void> _deleteUser(AdminUser user) async {
    final l = _l10n(context);
    try {
      final ok = await FirestoreService.deleteDocument('users/${user.id}');
      if (!mounted) return;
      if (ok) {
        // Build 290 (P1): 사용자 doc 만 삭제하면 그 사용자가 보낸 letter 본문 +
        // senderId/Name 이 다른 사용자 inbox + 지도에 영구 잔존 → PII 누출.
        // GDPR Art.17 준수를 위해 auth_service 의 best-effort scrub 와 동일하게
        // letter 본문 빈문자열 overwrite + senderId/Name 익명화.
        try {
          await FirestoreService.scrubLettersBySender(user.id);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[AdminDelete] letters scrub warning ${user.id}: $e');
          }
        }
        _users.removeWhere((u) => u.id == user.id);
        _applyFilter();
        _showSnack(l.koEn('🗑️ ${user.username} 삭제 완료', '🗑️ ${user.username} deleted'));
      } else {
        _showSnack(
          l.koEn(
            '삭제 실패 — Firebase 인증·규칙을 확인하세요',
            'Delete failed — check Firebase auth and rules',
          ),
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(l.koEn('삭제 실패: $e', 'Delete failed: $e'), isError: true);
    }
  }

  void _confirmDelete(AdminUser user) {
    final l = _l10n(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l.koEn('회원 삭제', 'Delete User'),
          style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
        ),
        content: Text(
          l.koEn(
            '${user.username}(${user.id})를 영구 삭제합니다.\n이 작업은 되돌릴 수 없습니다.',
            'Permanently delete ${user.username} (${user.id}).\nThis action cannot be undone.',
          ),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.koEn('취소', 'Cancel'), style: const TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(user);
            },
            child: Text(
              l.koEn('삭제', 'Delete'),
              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmToggleBan(AdminUser user) {
    final l = _l10n(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          user.isBanned
              ? l.koEn('차단 해제', 'Unban')
              : l.koEn('${user.username} 차단', 'Ban ${user.username}'),
          style: TextStyle(
            color: user.isBanned ? AppColors.teal : AppColors.error,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          user.isBanned
              ? l.koEn(
                  '${user.username}의 차단을 해제합니다.',
                  'Unban ${user.username}.',
                )
              : l.koEn(
                  '${user.username}(${user.id})를 차단합니다.\n차단된 회원은 앱에서 제한됩니다.',
                  'Ban ${user.username} (${user.id}).\nBanned users will be restricted in the app.',
                ),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l.koEn('취소', 'Cancel'),
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleBan(user);
            },
            child: Text(
              l.koEn('확인', 'Confirm'),
              style: TextStyle(
                color: user.isBanned ? AppColors.teal : AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = _l10n(context);
    final displayList = _searchCtrl.text.isEmpty ? _users : _filtered;
    final bannedCount = _users.where((u) => u.isBanned).length;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeep,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.koEn('👥 회원 관리', '👥 User Management'),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!_loading && _users.isNotEmpty)
              Text(
                l.koEn(
                  '총 ${_users.length}명  •  차단 ${bannedCount}명',
                  'Total ${_users.length} • Banned ${bannedCount}',
                ),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
            onPressed: _loading ? null : _fetchUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── 검색 + 정렬 ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              children: [
                // 검색창
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: l.koEn(
                      '닉네임, 나라, ID 검색',
                      'Search by nickname, country, ID',
                    ),
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchCtrl.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.bgCard,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.bgSurface,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.bgSurface,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.teal,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 정렬 탭
                Row(
                  children: [
                    _sortChip(l.koEn('타워순', 'Tower'), 'tower'),
                    const SizedBox(width: 6),
                    _sortChip(l.koEn('최근 활동', 'Recent'), 'recent'),
                    const SizedBox(width: 6),
                    _sortChip(l.koEn('발송 많은순', 'Most Sent'), 'sent'),
                  ],
                ),
              ],
            ),
          ),
          // ── 본문 ────────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.teal),
                        const SizedBox(height: 12),
                        Text(
                          l.koEn('회원 목록 불러오는 중...', 'Loading user list...'),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            color: AppColors.textMuted,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _fetchUsers,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(l.koEn('다시 시도', 'Retry')),
                          ),
                        ],
                      ),
                    ),
                  )
                : displayList.isEmpty
                ? Center(
                    child: Text(
                      l.koEn('회원이 없어요', 'No users found'),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    itemCount: displayList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) => _userTile(displayList[i]),
                  ),
          ),
        ],
      ),
    );
  }

  // ── 회원 목록 카드 ──────────────────────────────────────────────────────────
  Widget _userTile(AdminUser user) {
    return GestureDetector(
      onTap: () => _showUserDetail(user),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: user.isBanned
              ? AppColors.error.withValues(alpha: 0.05)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: user.isBanned
                ? AppColors.error.withValues(alpha: 0.25)
                : AppColors.bgSurface,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 국기 + 타워 이모지
            Stack(
              clipBehavior: Clip.none,
              children: [
                Text(user.countryFlag, style: const TextStyle(fontSize: 28)),
                Positioned(
                  right: -4,
                  bottom: -2,
                  child: Text(
                    user.tierEmoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // 닉네임 + 나라
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.username,
                          style: TextStyle(
                            color: user.isBanned
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            decoration: user.isBanned
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isBrand) ...[
                        const SizedBox(width: 4),
                        _chip('B', AppColors.coupon, small: true),
                      ] else if (user.isPremium) ...[
                        const SizedBox(width: 4),
                        _chip('P', AppColors.gold, small: true),
                      ],
                      if (user.isBanned) ...[
                        const SizedBox(width: 4),
                        _chip(
                          _l10n(context).koEn('차단', 'Banned'),
                          AppColors.error,
                          small: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _l10n(context).koEn(
                      '${user.country}  •  받음 ${user.receivedCount}  발송 ${user.sentCount}  ❤️ ${user.likeCount}',
                      '${user.country}  •  Received ${user.receivedCount}  Sent ${user.sentCount}  ❤️ ${user.likeCount}',
                    ),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 점수 + 화살표
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${user.towerHeight.toStringAsFixed(0)}pt',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── UI 헬퍼 ─────────────────────────────────────────────────────────────────
  Widget _sortChip(String label, String value) {
    final isActive = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = value);
        _applySort();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.teal.withValues(alpha: 0.15)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.teal : AppColors.bgSurface,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.teal : AppColors.textMuted,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, Color color, {bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 5 : 7,
        vertical: small ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _tierButton({
    required String label,
    required String emoji,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isActive ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.15)
              : AppColors.bgDeep,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: 0.6)
                : AppColors.textMuted.withValues(alpha: 0.25),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? color : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (isActive)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '✓',
                  style: TextStyle(color: color, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.teal,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontFamily: mono ? 'monospace' : null,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
