import 'package:flutter/services.dart';

/// Central sensory feedback for the 3 "letter moments" — opening a letter,
/// sending one, and an arrival landing in the mailbox. Today this is
/// haptic + SystemSound only (no asset plugin); when we ship the sound
/// layer with real audio files the internals of these three methods
/// change, the call sites don't.
///
/// Rationale for doing this as a service instead of inline HapticFeedback:
/// - one place to tune the "feel" of the app across screens
/// - one place to add the `audioplayers` package when ready, or to add
///   a settings toggle to silence the whole thing
/// - avoids duplicating the opening-sequence pattern (which is layered)
class FeedbackService {
  static bool _muted = false;

  /// Global mute — respected by all three moments. Settings UI can flip
  /// this to disable all feedback at once.
  static void setMuted(bool muted) {
    _muted = muted;
  }

  /// Fired when a user taps an envelope and the opening animation begins.
  /// Layered heavy+medium impact feels like a seal breaking.
  static Future<void> onLetterOpen() async {
    if (_muted) return;
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.mediumImpact();
      // System click gives a subtle "envelope seal pop" on devices with
      // sound — silent on muted devices.
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  /// Fired when a user sends a letter.  Short, decisive "it's off" feel.
  static Future<void> onLetterSend() async {
    if (_muted) return;
    try {
      await HapticFeedback.mediumImpact();
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  /// Fired when a new letter arrives in the mailbox (in-app). Softer than
  /// open — three staggered light pulses so it feels like a gentle
  /// mailbox nudge, not a notification.
  static Future<void> onLetterArrive() async {
    if (_muted) return;
    try {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 120));
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 120));
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }
}
