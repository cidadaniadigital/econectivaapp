import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class TransientVoiceSource {
  TransientVoiceSource._(this.source);
  final Source source;
  static Future<TransientVoiceSource> create(Uint8List wav) async =>
      TransientVoiceSource._(BytesSource(wav, mimeType: 'audio/wav'));
  Future<void> dispose() async {}
}
