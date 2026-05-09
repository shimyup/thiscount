import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/letter.dart';
import '../../state/app_state.dart';

/// Build 268: Brand 전용 redemption 내역 CSV export.
///
/// Brand 가 회계 / 정산 / 효율 측정용으로 본인이 발송한 letter 들의 redemption
/// 로그를 CSV 파일로 다운로드 + 공유. 이전엔 admin 만 인박스에서 통계 봐야
/// 했고 외부 시트 / 회계로 옮길 방법 zero.
///
/// 컬럼: id, sentAt, content_preview, expiresAt, readCount, redeemedCount,
///       destination, isAnonymous.
class BrandRedemptionExport {
  /// Brand 의 보낸 letter 를 CSV 한 줄씩으로 변환 + 저장 + share sheet.
  static Future<void> exportAndShare(BuildContext context) async {
    final state = context.read<AppState>();
    final l10n = AppL10n.of(state.currentUser.languageCode);
    final letters = state.sent;

    if (letters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.brandCsvEmpty),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final csv = _toCsv(letters);
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final path = '${dir.path}/thiscount_redemption_$ts.csv';
    final file = File(path);
    await file.writeAsString(csv);

    if (!context.mounted) return;
    await Share.shareXFiles(
      [XFile(path, name: 'thiscount_redemption_$ts.csv')],
      subject: l10n.brandCsvShareSubject,
      text: l10n.brandCsvShareText(letters.length),
    );
  }

  /// 메모리에 CSV 문자열만 만들어 클립보드 복사 (preview 등 용도).
  static Future<void> copyToClipboard(BuildContext context) async {
    final state = context.read<AppState>();
    final l10n = AppL10n.of(state.currentUser.languageCode);
    final csv = _toCsv(state.sent);
    await Clipboard.setData(ClipboardData(text: csv));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.brandCsvCopiedToast),
        backgroundColor: AppColors.teal,
      ),
    );
  }

  static String _toCsv(List<Letter> letters) {
    final buf = StringBuffer();
    // Header — RFC 4180 호환 (UTF-8 BOM 으로 Excel 한글 정상 인식).
    buf.write('﻿'); // BOM
    buf.writeln(
      'id,sentAt,senderName,destinationCountry,destinationCity,'
      'category,readCount,maxReaders,redeemedCount,expiresAt,'
      'redemptionInfo,contentPreview',
    );
    for (final l in letters) {
      buf.writeln([
        _csv(l.id),
        _csv(l.sentAt.toIso8601String()),
        _csv(l.isAnonymous ? 'Anonymous' : l.senderName),
        _csv(l.destinationCountry),
        _csv(l.destinationCity ?? ''),
        _csv(l.category.key),
        l.readCount,
        l.maxReaders,
        l.ratingCount, // proxy — 정식 redeem count 는 Firestore 만 가짐
        _csv(l.expiresAt?.toIso8601String() ?? ''),
        _csv(l.redemptionInfo ?? ''),
        _csv(_truncate(l.content, 80)),
      ].join(','));
    }
    return buf.toString();
  }

  static String _csv(String s) {
    // RFC 4180: 콤마/줄바꿈/큰따옴표 포함 시 큰따옴표로 감싸고 내부는 escape.
    if (s.contains(',') || s.contains('\n') || s.contains('"')) {
      final escaped = s.replaceAll('"', '""');
      return '"$escaped"';
    }
    return s;
  }

  static String _truncate(String s, int max) {
    final clean = s.replaceAll('\n', ' ').replaceAll('\r', ' ');
    if (clean.length <= max) return clean;
    return '${clean.substring(0, max)}…';
  }
}
