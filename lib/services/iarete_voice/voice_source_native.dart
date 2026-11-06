import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

/// Apple/Linux playback needs a file. Own that temporary file so it is removed
/// on stop, completion or panel close instead of the plugin's unmanaged cache.
class TransientVoiceSource {
  TransientVoiceSource._(this.source, this._directory);
  final Source source;
  final Directory? _directory;
  static Future<TransientVoiceSource> create(Uint8List wav) async {
    if (Platform.isAndroid || Platform.isWindows) {
      return TransientVoiceSource._(
        BytesSource(wav, mimeType: 'audio/wav'),
        null,
      );
    }
    final base = await getTemporaryDirectory();
    final directory = await Directory(
      '${base.path}/iarete-voice-',
    ).createTemp();
    final file = File('${directory.path}/mensagem.wav');
    try {
      await file.writeAsBytes(wav, flush: true);
      return TransientVoiceSource._(
        DeviceFileSource(file.path, mimeType: 'audio/wav'),
        directory,
      );
    } catch (_) {
      await directory.delete(recursive: true);
      rethrow;
    }
  }

  Future<void> dispose() async {
    try {
      if (await _directory?.exists() ?? false)
        await _directory!.delete(recursive: true);
    } catch (_) {}
  }
}
