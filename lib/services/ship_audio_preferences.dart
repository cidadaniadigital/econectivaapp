import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One audio choice for the cockpit and assistente's conversation.
abstract final class ShipAudioPreferences {
  static final enabled = ValueNotifier<bool>(true);
  static Future<void>? _restore;
  static int _revision = 0;
  static Future<void> restore() => _restore ??= _load();
  static Future<void> _load() async {
    final revision = _revision;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (revision == _revision)
        enabled.value = prefs.getBool('space_audio_enabled') ?? true;
    } catch (_) {
      /* Audio controls remain usable without local storage. */
    }
  }

  static Future<void> setEnabled(bool value) async {
    _revision++;
    enabled.value = value;
    try {
      await (await SharedPreferences.getInstance()).setBool(
        'space_audio_enabled',
        value,
      );
    } catch (_) {}
  }
}
