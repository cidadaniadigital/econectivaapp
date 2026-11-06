import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/services/iarete_voice/voice_conversation.dart';
const spaceChatAccent = Color(0xFF43D4C2);
const spaceChatText = Color(0xFFE7F0FF);
const spaceChatMuted = Color(0xFFA1AEC4);

class IareteVoiceControls extends StatelessWidget {
  const IareteVoiceControls({
    super.key,
    required this.voice,
    required this.sending,
    required this.onUseTranscript,
  });
  final VoiceConversation voice;
  final bool sending;
  final ValueChanged<String> onUseTranscript;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: voice,
    builder: (context, _) {
      final recording = voice.stage == VoiceStage.recording;
      final review = voice.stage == VoiceStage.review;
      final draft = recording || review || voice.stage == VoiceStage.stopping;
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xEE0A1C2B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: recording
                  ? const Color(0xFFD28B83)
                  : const Color(0xFF355965),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (draft) ...[
                Row(
                  children: [
                    Icon(
                      recording ? Icons.mic : Icons.graphic_eq,
                      color: recording
                          ? const Color(0xFFF2AAA0)
                          : spaceChatAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(voice.seconds ~/ 60).toString().padLeft(2, '0')}:${(voice.seconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: spaceChatText,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 26,
                        child: CustomPaint(
                          painter: _VoiceMeter(
                            recording ? voice.level : .14,
                            voice.seconds,
                            recording,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      recording ? 'GRAVANDO' : 'REVISAR',
                      style: const TextStyle(
                        color: spaceChatMuted,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              if (voice.busy ||
                  draft ||
                  voice.playing ||
                  voice.loadingId != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    voice.status,
                    style: const TextStyle(
                      color: spaceChatText,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              if (voice.stage == VoiceStage.thinking &&
                  voice.transcript != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Você disse: ${voice.transcript}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: spaceChatMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
              if (voice.error != null) ...[
                const SizedBox(height: 6),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    voice.error!,
                    style: const TextStyle(
                      color: Color(0xFFF2C0A4),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 2,
                children: [
                  if (recording) ...[
                    FilledButton.icon(
                      onPressed: voice.stopRecording,
                      icon: const Icon(Icons.stop_circle_outlined, size: 19),
                      label: const Text('Parar e revisar'),
                    ),
                    TextButton(
                      onPressed: voice.discard,
                      child: const Text('Cancelar'),
                    ),
                  ] else if (review) ...[
                    IconButton(
                      tooltip: voice.previewing && voice.playing
                          ? 'Parar prévia'
                          : 'Ouvir gravação',
                      onPressed: voice.preview,
                      icon: Icon(
                        voice.previewing && voice.playing
                            ? Icons.stop_circle_outlined
                            : Icons.play_circle_outline,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: sending ? null : voice.send,
                      icon: const Icon(Icons.send_outlined, size: 17),
                      label: const Text('Enviar áudio'),
                    ),
                    TextButton(
                      onPressed: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        voice.start();
                      },
                      child: const Text('Regravar'),
                    ),
                    IconButton(
                      onPressed: voice.discard,
                      tooltip: 'Descartar gravação',
                      icon: const Icon(Icons.delete_outline),
                    ),
                    if (voice.transcript != null)
                      TextButton(
                        onPressed: () {
                          onUseTranscript(voice.transcript!);
                          voice.discard();
                        },
                        child: const Text('Usar transcrição no texto'),
                      ),
                  ] else if (!voice.busy) ...[
                    TextButton.icon(
                      onPressed: sending
                          ? null
                          : () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              voice.start();
                            },
                      icon: const Icon(Icons.mic_none_outlined, size: 20),
                      label: const Text('Falar com assistente'),
                    ),
                    IconButton(
                      tooltip: voice.enabled
                          ? 'Desativar respostas por voz'
                          : 'Ativar respostas por voz',
                      onPressed: () => voice.setEnabled(!voice.enabled),
                      icon: Icon(
                        voice.enabled
                            ? Icons.record_voice_over_outlined
                            : Icons.voice_over_off_outlined,
                        color: voice.enabled ? spaceChatAccent : spaceChatMuted,
                      ),
                    ),
                    const Text(
                      'Voz gerada por IA',
                      style: TextStyle(color: spaceChatMuted, fontSize: 11),
                    ),
                  ],
                  if (voice.playing && !voice.previewing ||
                      voice.loadingId != null)
                    TextButton.icon(
                      onPressed: voice.stopPlayback,
                      icon: const Icon(Icons.stop_circle_outlined, size: 18),
                      label: const Text('Interromper voz'),
                    ),
                  if (voice.stage == VoiceStage.transcribing ||
                      voice.stage == VoiceStage.thinking ||
                      voice.stage == VoiceStage.permission ||
                      voice.stage == VoiceStage.stopping)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: spaceChatAccent,
                        ),
                      ),
                    ),
                ],
              ),
              if (review)
                const Text(
                  'O áudio será transcrito e descartado após o processamento. Limite: 2 minutos.',
                  style: TextStyle(
                    color: spaceChatMuted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _VoiceMeter extends CustomPainter {
  _VoiceMeter(this.level, this.time, this.recording);
  final double level;
  final int time;
  final bool recording;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = (recording ? spaceChatAccent : spaceChatMuted).withValues(
        alpha: .8,
      )
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < size.width / 6; i++) {
      final height =
          3 +
          (size.height - 4) *
              math.min(1, level * 5 + .06) *
              (.4 + .6 * math.sin(i * 1.7 + time).abs());
      canvas.drawLine(
        Offset(i * 6, (size.height - height) / 2),
        Offset(i * 6, (size.height + height) / 2),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_VoiceMeter old) =>
      old.level != level || old.time != time || old.recording != recording;
}
