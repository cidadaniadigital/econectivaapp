import 'dart:math' as math;
import 'package:unisinos_usp_app/services/iarete_voice/voice_source.dart';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

abstract interface class VoiceRecorder {
  Future<bool> requestPermission();
  Future<Stream<Uint8List>> start();
  Future<void> stop();
  Future<void> cancel();
  Future<void> dispose();
}

class MicrophoneRecorder implements VoiceRecorder {
  AudioRecorder? _recorder;
  AudioRecorder get _device => _recorder ??= AudioRecorder();
  @override
  Future<bool> requestPermission() => _device.hasPermission();
  @override
  Future<Stream<Uint8List>> start() => _device.startStream(
    const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
      echoCancel: true,
      noiseSuppress: true,
      autoGain: true,
    ),
  );
  @override
  Future<void> stop() async {
    await _recorder?.stop();
  }

  @override
  Future<void> cancel() async {
    await _recorder?.cancel();
  }

  @override
  Future<void> dispose() async {
    await _recorder?.dispose();
  }
}

abstract interface class VoicePlayer {
  Stream<void> get completed;
  Future<void> play(Uint8List wav);
  Future<void> stop();
  Future<void> dispose();
}

class IareteVoicePlayer implements VoicePlayer {
  AudioPlayer? _player;
  TransientVoiceSource? _source;
  int _revision = 0;
  AudioPlayer get _device => _player ??= AudioPlayer();
  @override
  Stream<void> get completed =>
      _device.onPlayerComplete.asyncMap((_) => _clear());
  @override
  Future<void> play(Uint8List wav) async {
    final revision = ++_revision;
    final source = await TransientVoiceSource.create(wav);
    if (revision != _revision) {
      await source.dispose();
      return;
    }
    await _clear();
    _source = source;
    await _device.play(
      source.source,
      ctx: AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.speech,
        ),
        iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
      ),
    );
  }

  Future<void> _clear() async {
    final source = _source;
    _source = null;
    await source?.dispose();
  }

  @override
  Future<void> stop() async {
    ++_revision;
    await _player?.stop();
    await _clear();
  }

  @override
  Future<void> dispose() async {
    ++_revision;
    await _player?.dispose();
    await _clear();
  }
}

Uint8List pcmToVoiceWav(Uint8List pcm) {
  final data = ByteData(44 + pcm.length);
  void label(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      data.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  label(0, 'RIFF');
  data.setUint32(4, 36 + pcm.length, Endian.little);
  label(8, 'WAVEfmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, 16000, Endian.little);
  data.setUint32(28, 32000, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  label(36, 'data');
  data.setUint32(40, pcm.length, Endian.little);
  data.buffer.asUint8List().setRange(44, 44 + pcm.length, pcm);
  return data.buffer.asUint8List();
}

/// A short local confirmation uses the same player as speech, so it cannot
/// steal audio focus from a reply that finishes unusually quickly.
Uint8List voiceAcknowledgement() {
  final pcm = ByteData(2400);
  for (var i = 0; i < 1200; i++) {
    final envelope = math.sin(math.pi * i / 1200);
    final sample = (math.sin(i * 2 * math.pi * 660 / 16000) * envelope * 1400)
        .round();
    pcm.setInt16(i * 2, sample, Endian.little);
  }
  return pcmToVoiceWav(pcm.buffer.asUint8List());
}
