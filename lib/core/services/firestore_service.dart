import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/firebase_config.dart';
import 'firebase_auth_service.dart';

/// Firestore REST API 서비스
/// Firebase SDK 없이 HTTP REST API로 Firestore에 접근
class FirestoreService {
  static String? _idToken; // Firebase Auth ID 토큰

  static void setIdToken(String token) {
    _idToken = token;
  }

  /// Build 136: StorageService 가 같은 ID 토큰으로 Firebase Storage REST
  /// 호출을 인증하기 위해 토큰을 읽을 수 있도록 노출. 다른 곳에서 쓰지 말 것.
  static String? get idToken => _idToken;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_idToken != null) 'Authorization': 'Bearer $_idToken',
  };

  /// 외부에서 직접 http.patch/post 를 만들 때 사용할 동일한 auth 헤더.
  /// rules 평가 대상이 되어야 하는 admin 작업(soft-delete 등) 에서 사용.
  static Map<String, String> get authHeaders => _headers;

  static Uri _buildUri(String path, {Map<String, String>? queryParameters}) {
    final base = '${FirebaseConfig.firestoreBase}/$path';
    final uri = Uri.parse(base);
    if (queryParameters == null || queryParameters.isEmpty) return uri;
    return uri.replace(
      queryParameters: {...uri.queryParameters, ...queryParameters},
    );
  }

  // ── 문서 읽기 ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getDocument(String path) async {
    if (!FirebaseConfig.kFirebaseEnabled) return null;
    await FirebaseAuthService.ensureValidToken();
    try {
      final res = await http
          .get(
            Uri.parse('${FirebaseConfig.firestoreBase}/$path'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[FirestoreService] 에러: $e\n$st');
    }
    return null;
  }

  // ── 문서 쓰기/업데이트 ───────────────────────────────────────────────────────
  //
  // Firestore REST API 의 PATCH 는 updateMask 를 명시하지 않으면 요청 body 에
  // 없는 기존 필드들을 "삭제" 처리한다. 이 서비스의 caller 들은 모두 "부분
  // 업데이트" 를 기대하므로, 전달받은 필드만 updateMask 로 지정해
  // 다른 필드가 동시에 살아남도록 한다.
  //
  // 이 가드가 없으면 위도/경도 저장과 초대코드 저장이 병렬로 날아가 서로의
  // 필드를 덮어 쓰는 경쟁 상태가 발생, 지도에서 좌표가 0,0 으로 보이는
  // 문제가 재현된다.
  static Future<bool> setDocument(
    String path,
    Map<String, dynamic> data,
  ) async {
    if (!FirebaseConfig.kFirebaseEnabled) return false;
    await FirebaseAuthService.ensureValidToken();
    try {
      final body = jsonEncode({'fields': _toFirestoreFields(data)});
      final maskParams = data.keys
          .map((k) => 'updateMask.fieldPaths=${Uri.encodeQueryComponent(k)}')
          .join('&');
      final separator = maskParams.isEmpty ? '' : '?$maskParams';
      final res = await http
          .patch(
            Uri.parse(
              '${FirebaseConfig.firestoreBase}/$path$separator',
            ),
            headers: _headers,
            body: body,
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[FirestoreService] 에러: $e\n$st');
    }
    return false;
  }

  // ── 문서 생성 (이미 존재하면 실패) ───────────────────────────────────────────
  static Future<CreateDocumentResult> createDocumentIfAbsent(
    String path,
    Map<String, dynamic> data,
  ) async {
    if (!FirebaseConfig.kFirebaseEnabled) return CreateDocumentResult.error;
    await FirebaseAuthService.ensureValidToken();
    try {
      final body = jsonEncode({'fields': _toFirestoreFields(data)});
      final res = await http
          .patch(
            _buildUri(
              path,
              queryParameters: {'currentDocument.exists': 'false'},
            ),
            headers: _headers,
            body: body,
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return CreateDocumentResult.created;
      if (res.statusCode == 409 || res.statusCode == 412) {
        return CreateDocumentResult.alreadyExists;
      }
      if (kDebugMode) debugPrint(
        '[FirestoreService] createDocumentIfAbsent 실패: ${res.statusCode} ${res.body}',
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('[FirestoreService] 에러: $e\n$st');
    }
    return CreateDocumentResult.error;
  }

  // ── 컬렉션 쿼리 ─────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> queryCollection(
    String collectionPath, {
    String? orderBy,
    int limit = 20,
  }) async {
    if (!FirebaseConfig.kFirebaseEnabled) return [];
    await FirebaseAuthService.ensureValidToken();
    try {
      var url =
          '${FirebaseConfig.firestoreBase}/$collectionPath?pageSize=$limit';
      if (orderBy != null) url += '&orderBy=$orderBy';
      final res = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final docs = body['documents'] as List<dynamic>? ?? [];
        return docs.cast<Map<String, dynamic>>();
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[FirestoreService] 에러: $e\n$st');
    }
    return [];
  }

  /// Build 138: 문서의 정수 필드를 원자적으로 증감. Firestore `:commit`
  /// 엔드포인트 + `fieldTransforms.increment` 사용. 여러 유저가 동시에
  /// 같은 편지를 주워도 counter 가 안전하게 증가.
  ///
  /// [path] 예: `letters/sent_123`
  /// [field] 예: `pickupCount`
  /// [by]  증감량 (음수 가능)
  static Future<bool> incrementField({
    required String path,
    required String field,
    int by = 1,
  }) async {
    if (!FirebaseConfig.kFirebaseEnabled) return false;
    await FirebaseAuthService.ensureValidToken();
    try {
      final docName =
          'projects/${FirebaseConfig.projectId}/databases/(default)/documents/$path';
      final body = jsonEncode({
        'writes': [
          {
            'transform': {
              'document': docName,
              'fieldTransforms': [
                {
                  'fieldPath': field,
                  'increment': {'integerValue': by.toString()},
                },
              ],
            },
          },
        ],
      });
      final commitUrl =
          'https://firestore.googleapis.com/v1/projects/${FirebaseConfig.projectId}'
          '/databases/(default)/documents:commit';
      final res = await http
          .post(Uri.parse(commitUrl), headers: _headers, body: body)
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FirestoreService] incrementField 에러: $e\n$st');
      }
    }
    return false;
  }

  // ── 문서 삭제 ────────────────────────────────────────────────────────────────
  static Future<bool> deleteDocument(String path) async {
    if (!FirebaseConfig.kFirebaseEnabled) return false;
    await FirebaseAuthService.ensureValidToken();
    try {
      final res = await http
          .delete(
            Uri.parse('${FirebaseConfig.firestoreBase}/$path'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[FirestoreService] 에러: $e\n$st');
    }
    return false;
  }

  /// Build 207: 회원 탈퇴 시 본인이 보낸 letters 의 PII 필드를 익명화.
  /// firestore.rules 의 letter update 화이트리스트가 본문/발신자/좌표 변경을
  /// 막고 있어 클라이언트가 직접 scrub 하지 못한다 — 대신 senderId 가 일치
  /// 하는 letter 들의 status 를 'deletedBySender' 로 mark, 후속 admin REST
  /// 작업에서 일괄 hard-delete.
  static Future<int> scrubLettersBySender(String senderId) async {
    if (!FirebaseConfig.kFirebaseEnabled) return 0;
    if (senderId.isEmpty) return 0;
    try {
      final docs = await queryWhereEquals(
        collectionId: 'letters',
        field: 'senderId',
        value: senderId,
        limit: 500,
      );
      int marked = 0;
      for (final doc in docs) {
        // 'name' 은 'projects/.../databases/.../documents/letters/{id}' 형식.
        final name = doc['name'] as String?;
        if (name == null || name.isEmpty) continue;
        final id = name.split('/').last;
        if (id.isEmpty) continue;
        try {
          // status='deletedBySender' 만 PATCH (rule 화이트리스트 통과).
          // updateMask 명시 안 하면 다른 필드를 비우려 시도해 거절될 수 있음.
          final url = Uri.parse(
            '${FirebaseConfig.firestoreBase}/letters/$id'
            '?updateMask.fieldPaths=status',
          );
          final body = jsonEncode({
            'fields': {
              'status': {'stringValue': 'deletedBySender'},
            },
          });
          await http
              .patch(url, headers: _headers, body: body)
              .timeout(const Duration(seconds: 8));
          marked++;
        } catch (_) {
          // 개별 letter 실패는 무시
        }
      }
      return marked;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[FirestoreService] scrubLetters 에러: $e\n$st');
      return 0;
    }
  }

  // ── 단일 조건 쿼리 (field == value) ─────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> queryWhereEquals({
    required String collectionId,
    required String field,
    required String value,
    int limit = 1,
  }) async {
    if (!FirebaseConfig.kFirebaseEnabled) return [];
    await FirebaseAuthService.ensureValidToken();
    try {
      final body = jsonEncode({
        'structuredQuery': {
          'from': [
            {'collectionId': collectionId},
          ],
          'where': {
            'fieldFilter': {
              'field': {'fieldPath': field},
              'op': 'EQUAL',
              'value': {'stringValue': value},
            },
          },
          'limit': limit,
        },
      });
      final res = await http
          .post(
            Uri.parse('${FirebaseConfig.firestoreBase}:runQuery'),
            headers: _headers,
            body: body,
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final rows = jsonDecode(res.body) as List<dynamic>;
        final docs = <Map<String, dynamic>>[];
        for (final row in rows) {
          final map = row as Map<String, dynamic>;
          final doc = map['document'];
          if (doc is Map<String, dynamic>) {
            docs.add(doc);
          }
        }
        return docs;
      }
      if (kDebugMode) debugPrint(
        '[FirestoreService] queryWhereEquals 실패: ${res.statusCode} ${res.body}',
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('[FirestoreService] 에러: $e\n$st');
    }
    return [];
  }

  // ── 복합 조건 쿼리 (여러 field == value) ──────────────────────────────────────
  static Future<List<Map<String, dynamic>>> queryWhereComposite({
    required String collectionId,
    required Map<String, String> conditions, // {field: value, ...}
    int limit = 20,
  }) async {
    if (!FirebaseConfig.kFirebaseEnabled) return [];
    await FirebaseAuthService.ensureValidToken();
    try {
      final filters = conditions.entries.map((e) => {
        'fieldFilter': {
          'field': {'fieldPath': e.key},
          'op': 'EQUAL',
          'value': {'stringValue': e.value},
        },
      }).toList();

      final where = filters.length == 1
          ? filters.first
          : {
              'compositeFilter': {
                'op': 'AND',
                'filters': filters,
              },
            };

      final body = jsonEncode({
        'structuredQuery': {
          'from': [{'collectionId': collectionId}],
          'where': where,
          'limit': limit,
        },
      });
      final res = await http
          .post(
            Uri.parse('${FirebaseConfig.firestoreBase}:runQuery'),
            headers: _headers,
            body: body,
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final rows = jsonDecode(res.body) as List<dynamic>;
        final docs = <Map<String, dynamic>>[];
        for (final row in rows) {
          final map = row as Map<String, dynamic>;
          final doc = map['document'];
          if (doc is Map<String, dynamic>) docs.add(doc);
        }
        return docs;
      }
      if (kDebugMode) debugPrint(
        '[FirestoreService] queryWhereComposite 실패: ${res.statusCode} ${res.body}',
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('[FirestoreService] 에러: $e\n$st');
    }
    return [];
  }

  // ── Dart Map → Firestore Fields 변환 ────────────────────────────────────────
  static Map<String, dynamic> _toFirestoreFields(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    data.forEach((key, value) {
      if (value is String) {
        result[key] = {'stringValue': value};
      } else if (value is int) {
        result[key] = {'integerValue': value.toString()};
      } else if (value is double) {
        result[key] = {'doubleValue': value};
      } else if (value is bool) {
        result[key] = {'booleanValue': value};
      } else if (value is List) {
        result[key] = {
          'arrayValue': {
            'values': value.map((e) => _toFirestoreValue(e)).toList(),
          },
        };
      } else if (value is Map) {
        result[key] = {
          'mapValue': {
            'fields': _toFirestoreFields(value.cast<String, dynamic>()),
          },
        };
      } else if (value == null) {
        result[key] = {'nullValue': null};
      }
    });
    return result;
  }

  static dynamic _toFirestoreValue(dynamic value) {
    if (value is String) return {'stringValue': value};
    if (value is int) return {'integerValue': value.toString()};
    if (value is double) return {'doubleValue': value};
    if (value is bool) return {'booleanValue': value};
    if (value is Map)
      return {
        'mapValue': {
          'fields': _toFirestoreFields(value.cast<String, dynamic>()),
        },
      };
    return {'nullValue': null};
  }

  // ── Firestore Fields → Dart Map 변환 ────────────────────────────────────────
  static Map<String, dynamic> fromFirestoreDoc(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};
    return _fromFirestoreFields(fields);
  }

  static Map<String, dynamic> _fromFirestoreFields(
    Map<String, dynamic> fields,
  ) {
    final result = <String, dynamic>{};
    fields.forEach((key, value) {
      result[key] = _fromFirestoreValue(value as Map<String, dynamic>);
    });
    return result;
  }

  static dynamic _fromFirestoreValue(Map<String, dynamic> value) {
    if (value.containsKey('stringValue')) return value['stringValue'];
    if (value.containsKey('integerValue'))
      return int.tryParse(value['integerValue'].toString()) ?? 0;
    if (value.containsKey('doubleValue'))
      return (value['doubleValue'] as num).toDouble();
    if (value.containsKey('booleanValue')) return value['booleanValue'];
    if (value.containsKey('timestampValue')) return value['timestampValue'];
    if (value.containsKey('referenceValue')) return value['referenceValue'];
    if (value.containsKey('nullValue')) return null;
    if (value.containsKey('arrayValue')) {
      final values =
          (value['arrayValue'] as Map<String, dynamic>)['values'] as List? ??
          [];
      return values
          .map((e) => _fromFirestoreValue(e as Map<String, dynamic>))
          .toList();
    }
    if (value.containsKey('mapValue')) {
      final fields =
          (value['mapValue'] as Map<String, dynamic>)['fields']
              as Map<String, dynamic>? ??
          {};
      return _fromFirestoreFields(fields);
    }
    return null;
  }
}

enum CreateDocumentResult { created, alreadyExists, error }
