import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central sensory feedback for the core "letter moments" — open, send,
/// arrive, pickup, level-up, purchase. Build 182 에서 audioplayers 통합 완료.
///
/// Rationale for doing this as a service instead of inline HapticFeedback:
/// - one place to tune the "feel" of the app across screens
/// - one place to swap the audio backend or add a settings toggle
/// - sound/haptic 모두 한 곳에서 mute 처리
class FeedbackService {
  static bool _mutedHaptic = false;
  static bool _mutedSound = false;
  static const _prefSoundKey = 'fx_sound_muted';
  static const _prefHapticKey = 'fx_haptic_muted';

  // 사운드마다 독립된 AudioPlayer 를 쓰면 연속 발생 시에도 잘린 소리 없이
  // 겹쳐 재생할 수 있다. tap / pickup 등 짧은 효과를 빠르게 연타할 때 필수.
  static final Map<_Sfx, AudioPlayer> _players = {
    for (final s in _Sfx.values) s: AudioPlayer()..setReleaseMode(ReleaseMode.stop),
  };
  static bool _preloaded = false;

  /// 앱 시작 시 한 번 호출 — SharedPreferences 에서 mute 복원 + 사운드 프리로드.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _mutedSound = prefs.getBool(_prefSoundKey) ?? false;
      _mutedHaptic = prefs.getBool(_prefHapticKey) ?? false;
    } catch (_) {}
    await _preloadSounds();
  }

  static Future<void> _preloadSounds() async {
    if (_preloaded) return;
    _preloaded = true;
    try {
      for (final s in _Sfx.values) {
        final player = _players[s]!;
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setSource(AssetSource('sounds/${s.file}'));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[FeedbackService] preload 실패: $e');
    }
  }

  static Future<void> setSoundMuted(bool muted) async {
    _mutedSound = muted;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefSoundKey, muted);
    } catch (_) {}
  }

  static Future<void> setHapticMuted(bool muted) async {
    _mutedHaptic = muted;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefHapticKey, muted);
    } catch (_) {}
  }

  static bool get isSoundMuted => _mutedSound;
  static bool get isHapticMuted => _mutedHaptic;

  /// 하위호환 — 예전 호출부가 이 이름을 쓰고 있음. 두 채널 모두 뮤트.
  static void setMuted(bool muted) {
    _mutedHaptic = muted;
    _mutedSound = muted;
  }

  static Future<void> _play(_Sfx sfx) async {
    if (_mutedSound) return;
    try {
      final player = _players[sfx]!;
      // 재생 중이어도 겹쳐 다시 재생 — 연타 대응.
      await player.stop();
      await player.play(AssetSource('sounds/${sfx.file}'));
    } catch (e) {
      if (kDebugMode) debugPrint('[FeedbackService] play ${sfx.file} 실패: $e');
    }
  }

  static Future<void> _haptic(Future<void> Function() f) async {
    if (_mutedHaptic) return;
    try {
      await f();
    } catch (_) {}
  }

  /// Fired when a user taps an envelope and the opening animation begins.
  /// Layered heavy+medium impact feels like a seal breaking.
  static Future<void> onLetterOpen() async {
    unawaited(_play(_Sfx.open));
    await _haptic(() async {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.mediumImpact();
    });
  }

  /// Fired when a user sends a letter. Short, decisive "it's off" feel.
  static Future<void> onLetterSend() async {
    unawaited(_play(_Sfx.send));
    await _haptic(() async {
      await HapticFeedback.mediumImpact();
    });
  }

  /// Fired when a new letter arrives in the mailbox (in-app). 세 번 가볍게.
  static Future<void> onLetterArrive() async {
    unawaited(_play(_Sfx.tap));
    await _haptic(() async {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 120));
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 120));
      await HapticFeedback.lightImpact();
    });
  }

  /// Fired when the user successfully picks up a scattered letter from the
  /// map. Brand-sent letters get an extra heavy tap for weight.
  static Future<void> onLetterPickUp({bool isBrand = false}) async {
    unawaited(_play(_Sfx.pickup));
    await _haptic(() async {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.mediumImpact();
      if (isBrand) {
        await Future.delayed(const Duration(milliseconds: 120));
        await HapticFeedback.heavyImpact();
      }
    });
  }

  /// Build 182: 레벨 업 — 코드 chime + 중간 임팩트.
  static Future<void> onLevelUp() async {
    unawaited(_play(_Sfx.levelup));
    await _haptic(() async {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 120));
      await HapticFeedback.heavyImpact();
    });
  }

  /// Build 182: 구매·보상 — 코인 chime.
  static Future<void> onPurchaseSuccess() async {
    unawaited(_play(_Sfx.purchase));
    await _haptic(() async {
      await HapticFeedback.mediumImpact();
    });
  }

  /// Build 182: 경량 탭 효과 — 버튼 선택/중요한 토글에.
  static Future<void> onTap() async {
    unawaited(_play(_Sfx.tap));
    await _haptic(() async {
      await HapticFeedback.selectionClick();
    });
  }
}

/// 미래 추가될 사운드를 한 곳에서 관리. file 은 assets/sounds/ 기준.
enum _Sfx {
  open('open.wav'),
  send('send.wav'),
  pickup('pickup.wav'),
  levelup('levelup.wav'),
  purchase('purchase.wav'),
  tap('tap.wav');

  final String file;
  const _Sfx(this.file);
}

