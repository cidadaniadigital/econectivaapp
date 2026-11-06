import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisinos_usp_app/models/ai_assistant_message_model.dart';
import 'package:unisinos_usp_app/services/ship_audio_preferences.dart';
import 'package:unisinos_usp_app/services/iarete_voice/voice_api.dart';
import 'package:unisinos_usp_app/services/iarete_voice/voice_devices.dart';

enum VoiceStage {
  idle,
  permission,
  recording,
  stopping,
  review,
  transcribing,
  thinking,
}

/// One conversation owns one microphone and one player. Async results are ignored
/// after close/background/mute; audio is kept only in bounded volatile memory.
class VoiceConversation extends ChangeNotifier {
  VoiceConversation({
    required this.sendText,
    VoiceApi? api,
    VoiceRecorder? recorder,
    VoicePlayer? player,
  }) : api = api ?? IareteVoiceApi(),
       recorder = recorder ?? MicrophoneRecorder(),
       player = player ?? IareteVoicePlayer() {
    ShipAudioPreferences.enabled.addListener(_masterChanged);
  }
  final Future<AiAssistantMessageModel?> Function(String) sendText;
  final VoiceApi api;
  final VoiceRecorder recorder;
  final VoicePlayer player;
  StreamSubscription<Uint8List>? _microphone;
  StreamSubscription<void>? _complete;
  Timer? _clock;
  final _pcm = BytesBuilder(copy: false);
  VoiceStage stage = VoiceStage.idle;
  Uint8List? recording;
  String? transcript, error;
  int seconds = 0;
  double level = 0;
  bool enabled = true, playing = false, previewing = false;
  int? speakingId, loadingId;
  int _playRevision = 0, _revision = 0;
  bool _disposed = false, _foreground = true;
  final _cache = <int, Uint8List>{};
  bool get busy => stage != VoiceStage.idle && stage != VoiceStage.review;
  bool get hasDraft => recording != null || stage == VoiceStage.recording;
  bool get wantsVoice => enabled && ShipAudioPreferences.enabled.value;
  String get status => switch (stage) {
    VoiceStage.permission =>
      'Permita o uso do microfone para falar com a assistente.',
    VoiceStage.recording => 'Estou ouvindo. Pare a gravação para revisar.',
    VoiceStage.stopping => 'Preparando sua gravação…',
    VoiceStage.review =>
      transcript == null
          ? 'Ouça antes de enviar, grave novamente ou descarte.'
          : 'Transcrição pronta. Você pode tentar enviar novamente ou usar o texto.',
    VoiceStage.transcribing => 'Recebi seu áudio. Estou ouvindo…',
    VoiceStage.thinking => 'Entendi. Estou pensando na sua resposta…',
    VoiceStage.idle =>
      loadingId != null
          ? 'Preparando a voz da assistente…'
          : playing && !previewing
          ? 'assistente está falando…'
          : 'Converse por texto ou áudio.',
  };
  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!_disposed) {
        enabled = prefs.getBool('iarete_voice_enabled') ?? true;
        _emit();
      }
    } catch (_) {}
  }

  Future<void> setEnabled(bool value) async {
    enabled = value;
    if (!value) await stopPlayback();
    _emit();
    try {
      await (await SharedPreferences.getInstance()).setBool(
        'iarete_voice_enabled',
        value,
      );
    } catch (_) {}
  }

  void _masterChanged() {
    if (!ShipAudioPreferences.enabled.value) unawaited(stopPlayback());
    _emit();
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> start() async {
    if (_disposed || busy) return;
    stage = VoiceStage.permission;
    final revision = ++_revision;
    _emit();
    await stopPlayback();
    if (_disposed || revision != _revision) return;
    recording = null;
    transcript = null;
    _pcm.clear();
    seconds = 0;
    level = 0;
    error = null;
    stage = VoiceStage.permission;
    _emit();
    try {
      if (!await recorder.requestPermission()) {
        throw const VoiceException(
          'O microfone não foi autorizado. Permita o acesso nas configurações ou continue por texto.',
        );
      }
      if (_disposed || revision != _revision) return;
      final stream = await recorder.start();
      if (_disposed || revision != _revision) {
        await recorder.cancel();
        return;
      }
      stage = VoiceStage.recording;
      _microphone = stream.listen(
        (chunk) {
          if (_disposed ||
              (stage != VoiceStage.recording && stage != VoiceStage.stopping))
            return;
          final room = 120 * 32000 - _pcm.length;
          if (room > 0)
            _pcm.add(
              chunk.length <= room
                  ? chunk
                  : Uint8List.sublistView(chunk, 0, room),
            );
          final data = ByteData.sublistView(chunk);
          double energy = 0;
          for (var i = 0; i + 1 < data.lengthInBytes; i += 2) {
            final v = data.getInt16(i, Endian.little) / 32768;
            energy += v * v;
          }
          level = math.sqrt(energy / math.max(1, chunk.length / 2)).clamp(0, 1);
          _emit();
          if (_pcm.length >= 120 * 32000) unawaited(stopRecording());
        },
        onError: (_) {
          error =
              'A gravação foi interrompida. Você pode revisar o trecho captado.';
          unawaited(stopRecording());
        },
        onDone: () {
          if (!_disposed && stage == VoiceStage.recording)
            unawaited(stopRecording());
        },
      );
      _clock = Timer.periodic(const Duration(seconds: 1), (_) {
        seconds++;
        _emit();
        if (seconds >= 120) unawaited(stopRecording());
      });
      _emit();
    } catch (e) {
      if (!_disposed && revision == _revision) {
        stage = VoiceStage.idle;
        error = e is VoiceException
            ? e.message
            : 'Não foi possível acessar o microfone. Confira a permissão e tente novamente.';
        _emit();
      }
    }
  }

  Future<void> stopRecording() async {
    if (_disposed || stage != VoiceStage.recording) return;
    stage = VoiceStage.stopping;
    _clock?.cancel();
    _emit();
    try {
      await recorder.stop();
    } catch (_) {}
    await _microphone?.cancel();
    _microphone = null;
    if (_disposed) return;
    final pcm = _pcm.takeBytes();
    level = 0;
    if (pcm.length < 16000) {
      stage = VoiceStage.idle;
      error = 'A gravação ficou muito curta. Fale por pelo menos meio segundo.';
    } else {
      recording = pcmToVoiceWav(pcm);
      seconds = (pcm.length / 32000).ceil();
      stage = VoiceStage.review;
    }
    _emit();
  }

  Future<void> discard() async {
    if (stage == VoiceStage.transcribing ||
        stage == VoiceStage.thinking ||
        stage == VoiceStage.stopping)
      return;
    ++_revision;
    _clock?.cancel();
    await stopPlayback();
    try {
      await recorder.cancel();
    } catch (_) {}
    await _microphone?.cancel();
    _microphone = null;
    _pcm.clear();
    recording = null;
    transcript = null;
    seconds = 0;
    level = 0;
    stage = VoiceStage.idle;
    error = null;
    _emit();
  }

  Future<void> preview() async {
    if (recording == null || busy) return;
    if (playing && previewing) {
      await stopPlayback();
      return;
    }
    await _play(recording!, preview: true);
  }

  Future<void> send() async {
    if (_disposed || stage != VoiceStage.review || recording == null) return;
    final revision = ++_revision;
    error = null;
    stage = transcript == null ? VoiceStage.transcribing : VoiceStage.thinking;
    _emit();
    await stopPlayback();
    if (_disposed) return;
    try {
      if (transcript == null &&
          _foreground &&
          ShipAudioPreferences.enabled.value) {
        try {
          await player.play(voiceAcknowledgement());
        } catch (_) {}
        if (_disposed || revision != _revision) return;
      }
      transcript ??= await api.transcribe(recording!);
      if (_disposed || revision != _revision) return;
      stage = VoiceStage.thinking;
      _emit();
      final reply = await sendText(transcript!);
      if (_disposed || revision != _revision) return;
      if (reply == null) {
        throw const VoiceException(
          'Não foi possível enviar a mensagem. Confira o histórico antes de tentar novamente; sua gravação e transcrição continuam disponíveis.',
        );
      }
      recording = null;
      transcript = null;
      stage = VoiceStage.idle;
      seconds = 0;
      _emit();
      if (wantsVoice && reply.id != null) {
        await speak(reply.id!);
      } else {
        await stopPlayback();
      }
    } catch (e) {
      if (!_disposed && revision == _revision) {
        stage = VoiceStage.review;
        error = e is VoiceException
            ? e.message
            : 'Não foi possível processar o áudio. Sua gravação foi preservada para tentar novamente.';
        _emit();
      }
    }
  }

  Future<void> speak(int id, {bool manual = false}) async {
    if (_disposed || !_foreground || hasDraft || busy) return;
    if (speakingId == id && playing) {
      await stopPlayback();
      return;
    }
    if (manual) {
      await setEnabled(true);
      await ShipAudioPreferences.setEnabled(true);
    }
    await stopPlayback();
    if (_disposed) return;
    final rev = ++_playRevision;
    loadingId = id;
    error = null;
    _emit();
    try {
      var bytes = _cache[id];
      bytes ??= await api.speech(id);
      if (_disposed || rev != _playRevision) return;
      // At most two replies are retained, only for this open panel.
      if (_cache.length >= 2) _cache.remove(_cache.keys.first);
      _cache[id] = bytes;
      loadingId = null;
      if (!wantsVoice || !_foreground) {
        _emit();
        return;
      }
      speakingId = id;
      await _play(bytes, preview: false, revision: rev);
    } catch (e) {
      if (!_disposed && rev == _playRevision) {
        loadingId = null;
        speakingId = null;
        playing = false;
        error = e is VoiceException
            ? e.message
            : 'A resposta está em texto. Toque em Ouvir resposta para tentar reproduzir o áudio.';
        _emit();
      }
    }
  }

  Future<void> _play(
    Uint8List wav, {
    required bool preview,
    int? revision,
  }) async {
    final rev = revision ?? ++_playRevision;
    try {
      await _complete?.cancel();
      _complete = player.completed.listen((_) {
        if (!_disposed && rev == _playRevision) {
          playing = false;
          previewing = false;
          speakingId = null;
          _emit();
        }
      });
      previewing = preview;
      playing = true;
      _emit();
      await player.play(wav);
    } catch (_) {
      if (!_disposed && rev == _playRevision) {
        playing = false;
        previewing = false;
        speakingId = null;
        error =
            'A reprodução foi bloqueada ou interrompida. Toque em Ouvir para tentar novamente.';
        _emit();
      }
    }
  }

  Future<void> stopPlayback() async {
    ++_playRevision;
    loadingId = null;
    playing = false;
    previewing = false;
    speakingId = null;
    try {
      await player.stop();
    } catch (_) {}
    _emit();
  }

  void foreground() {
    _foreground = true;
  }

  void background() {
    _foreground = false;
    unawaited(stopPlayback());
    if (stage == VoiceStage.recording) unawaited(stopRecording());
    if (stage == VoiceStage.permission) {
      ++_revision;
      stage = VoiceStage.idle;
      _emit();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_revision;
    ++_playRevision;
    _clock?.cancel();
    _microphone?.cancel();
    _complete?.cancel();
    ShipAudioPreferences.enabled.removeListener(_masterChanged);
    api.close();
    _pcm.clear();
    recording = null;
    _cache.clear();
    unawaited(recorder.dispose().catchError((_) {}));
    unawaited(player.dispose().catchError((_) {}));
    super.dispose();
  }
}
