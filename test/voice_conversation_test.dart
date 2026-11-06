import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisinos_usp_app/models/ai_assistant_message_model.dart';
import 'package:unisinos_usp_app/services/iarete_voice/voice_api.dart';
import 'package:unisinos_usp_app/services/iarete_voice/voice_conversation.dart';
import 'package:unisinos_usp_app/services/iarete_voice/voice_devices.dart';
import 'package:unisinos_usp_app/services/ship_audio_preferences.dart';

class TestRecorder implements VoiceRecorder {
  bool permission = true, disposed = false;
  int stops = 0;
  final chunks = StreamController<Uint8List>();
  @override
  Future<bool> requestPermission() async => permission;
  @override
  Future<Stream<Uint8List>> start() async => chunks.stream;
  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> cancel() async {}
  @override
  Future<void> dispose() async {
    disposed = true;
    await chunks.close();
  }

  void feed() => chunks.add(
    Uint8List.fromList(List.generate(32000, (i) => i % 2 == 0 ? 100 : 0)),
  );
}

class TestPlayer implements VoicePlayer {
  final events = StreamController<void>.broadcast();
  int plays = 0, stops = 0;
  @override
  Stream<void> get completed => events.stream;
  @override
  Future<void> play(Uint8List wav) async {
    plays++;
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> dispose() async {
    await events.close();
  }
}

class TestVoiceApi implements VoiceApi {
  int transcriptions = 0, speeches = 0;
  bool failTranscription = false, failSpeech = false;
  Completer<Uint8List>? pendingSpeech;
  @override
  Future<String> transcribe(Uint8List wav) async {
    transcriptions++;
    if (failTranscription) throw const VoiceException('Falha temporária');
    return 'Como explorar a Terra?';
  }

  @override
  Future<Uint8List> speech(int id) async {
    speeches++;
    if (failSpeech) throw const VoiceException('Voz indisponível');
    if (pendingSpeech != null) return await pendingSpeech!.future;
    return pcmToVoiceWav(Uint8List(32000));
  }

  @override
  void close() {}
}

AiAssistantMessageModel voiceReply() => AiAssistantMessageModel(
  id: 8,
  role: 'assistant',
  content: 'Vamos explorar!',
  createdAt: DateTime(2026),
);
Future<void> draft(VoiceConversation voice, TestRecorder recorder) async {
  await voice.start();
  recorder.feed();
  await Future<void>.delayed(Duration.zero);
  await voice.stopRecording();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ShipAudioPreferences.setEnabled(true);
  });
  test('PCM envelope preserves sample rate, size, channel and sample data', () {
    final pcm = Uint8List.fromList([1, 0, 2, 0]);
    final wav = pcmToVoiceWav(pcm);
    final data = ByteData.sublistView(wav);
    expect(wav.length, 48);
    expect(data.getUint32(24, Endian.little), 16000);
    expect(data.getUint16(22, Endian.little), 1);
    expect(wav.sublist(44), pcm);
  });
  test(
    'review sends nothing; send transcribes once, preserves text and speaks',
    () async {
      final recorder = TestRecorder();
      final api = TestVoiceApi();
      final player = TestPlayer();
      final sent = <String>[];
      final voice = VoiceConversation(
        recorder: recorder,
        api: api,
        player: player,
        sendText: (text) async {
          sent.add(text);
          return voiceReply();
        },
      );
      addTearDown(voice.dispose);
      await draft(voice, recorder);
      expect(voice.stage, VoiceStage.review);
      expect(api.transcriptions, 0);
      expect(sent, isEmpty);
      await voice.preview();
      expect(player.plays, 1);
      await voice.send();
      expect(sent, ['Como explorar a Terra?']);
      expect(api.transcriptions, 1);
      expect(api.speeches, 1);
      expect(player.plays, 3);
      expect(voice.recording, isNull);
      expect(voice.playing, isTrue);
      await voice.send();
      expect(sent.length, 1);
      await voice.stopPlayback();
      expect(voice.playing, isFalse);
    },
  );
  test(
    'transcription failure retains recording for retry and cancellation discards it',
    () async {
      final recorder = TestRecorder();
      final api = TestVoiceApi()..failTranscription = true;
      var sent = 0;
      final voice = VoiceConversation(
        recorder: recorder,
        api: api,
        player: TestPlayer(),
        sendText: (_) async {
          sent++;
          return voiceReply();
        },
      );
      addTearDown(voice.dispose);
      await draft(voice, recorder);
      final wav = voice.recording;
      await voice.send();
      expect(voice.recording, same(wav));
      expect(voice.stage, VoiceStage.review);
      expect(sent, 0);
      api.failTranscription = false;
      await voice.send();
      expect(sent, 1);
      expect(voice.error, isNull);
    },
  );
  test(
    'chat failure preserves recognized text; retry does not transcribe or send twice concurrently',
    () async {
      final recorder = TestRecorder();
      final api = TestVoiceApi();
      var sent = 0;
      bool fail = true;
      final voice = VoiceConversation(
        recorder: recorder,
        api: api,
        player: TestPlayer(),
        sendText: (_) async {
          sent++;
          return fail ? null : voiceReply();
        },
      );
      addTearDown(voice.dispose);
      await draft(voice, recorder);
      await voice.send();
      expect(voice.transcript, 'Como explorar a Terra?');
      expect(voice.stage, VoiceStage.review);
      fail = false;
      await Future.wait([voice.send(), voice.send()]);
      expect(api.transcriptions, 1);
      expect(sent, 2);
    },
  );
  test('voice failure keeps successful chat and never resends it', () async {
    final recorder = TestRecorder();
    final api = TestVoiceApi()..failSpeech = true;
    var sent = 0;
    final voice = VoiceConversation(
      recorder: recorder,
      api: api,
      player: TestPlayer(),
      sendText: (_) async {
        sent++;
        return voiceReply();
      },
    );
    addTearDown(voice.dispose);
    await draft(voice, recorder);
    await voice.send();
    expect(sent, 1);
    expect(voice.stage, VoiceStage.idle);
    expect(voice.error, 'Voz indisponível');
    expect(voice.recording, isNull);
    api.failSpeech = false;
    await voice.speak(8);
    expect(sent, 1);
    expect(voice.playing, isTrue);
  });
  test('denied microphone and short recordings leave text usable', () async {
    final recorder = TestRecorder()..permission = false;
    final voice = VoiceConversation(
      recorder: recorder,
      api: TestVoiceApi(),
      player: TestPlayer(),
      sendText: (_) async => voiceReply(),
    );
    addTearDown(voice.dispose);
    await voice.start();
    expect(voice.stage, VoiceStage.idle);
    expect(voice.error, contains('não foi autorizado'));
    recorder.permission = true;
    await voice.start();
    await voice.stopRecording();
    expect(voice.recording, isNull);
    expect(voice.error, contains('curta'));
  });
  test(
    'muting stops voice, persists preference and ignores pending audio',
    () async {
      final api = TestVoiceApi()..pendingSpeech = Completer<Uint8List>();
      final player = TestPlayer();
      final voice = VoiceConversation(
        api: api,
        recorder: TestRecorder(),
        player: player,
        sendText: (_) async => voiceReply(),
      );
      addTearDown(voice.dispose);
      final task = voice.speak(8);
      await Future<void>.delayed(Duration.zero);
      await voice.setEnabled(false);
      api.pendingSpeech!.complete(pcmToVoiceWav(Uint8List(32000)));
      await task;
      expect(player.plays, 0);
      expect(voice.playing, isFalse);
      expect(
        (await SharedPreferences.getInstance()).getBool('iarete_voice_enabled'),
        false,
      );
    },
  );
  test(
    'background stops recording into review and never starts a late voice',
    () async {
      final recorder = TestRecorder();
      final api = TestVoiceApi();
      final player = TestPlayer();
      final voice = VoiceConversation(
        api: api,
        recorder: recorder,
        player: player,
        sendText: (_) async => voiceReply(),
      );
      addTearDown(voice.dispose);
      await voice.start();
      recorder.feed();
      await Future<void>.delayed(Duration.zero);
      voice.background();
      await Future<void>.delayed(Duration.zero);
      expect(voice.stage, VoiceStage.review);
      expect(recorder.stops, 1);
      await voice.send();
      expect(player.plays, 0);
      expect(api.speeches, 0);
    },
  );
  test('cancel discards draft without contacting provider', () async {
    final recorder = TestRecorder();
    final api = TestVoiceApi();
    final voice = VoiceConversation(
      api: api,
      recorder: recorder,
      player: TestPlayer(),
      sendText: (_) async => voiceReply(),
    );
    addTearDown(voice.dispose);
    await draft(voice, recorder);
    await voice.discard();
    expect(voice.recording, isNull);
    expect(voice.transcript, isNull);
    expect(voice.stage, VoiceStage.idle);
    expect(api.transcriptions, 0);
  });
  test(
    'closing ignores late synthesis, no notifier or player after dispose',
    () async {
      final api = TestVoiceApi()..pendingSpeech = Completer<Uint8List>();
      final player = TestPlayer();
      final voice = VoiceConversation(
        api: api,
        recorder: TestRecorder(),
        player: player,
        sendText: (_) async => voiceReply(),
      );
      final task = voice.speak(8);
      await Future<void>.delayed(Duration.zero);
      voice.dispose();
      api.pendingSpeech!.complete(pcmToVoiceWav(Uint8List(32000)));
      await task;
      expect(player.plays, 0);
    },
  );
}
