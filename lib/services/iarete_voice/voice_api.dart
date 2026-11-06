import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:widgets_spo/services/services.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';

abstract interface class VoiceApi {
  Future<String> transcribe(Uint8List wav);
  Future<Uint8List> speech(int messageId);
  void close();
}

class VoiceException implements Exception {
  const VoiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Audio requests have no body logging, public URLs or credentials in query strings.
class IareteVoiceApi implements VoiceApi {
  IareteVoiceApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  Uri _uri(String path) {
    return Uri.parse('${WebClient.apiBaseUrl}/ai/voice/$path');
  }

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${AuthProvider.instance.getToken()}',
    'Accept': 'application/json',
  };
  @override
  Future<String> transcribe(Uint8List wav) async {
    final request = http.MultipartRequest('POST', _uri('transcriptions'))
      ..headers.addAll(_headers)
      ..files.add(
        http.MultipartFile.fromBytes('file', wav, filename: 'mensagem.wav'),
      );
    final streamed = await _client
        .send(request)
        .timeout(const Duration(seconds: 100));
    final response = await http.Response.fromStream(
      streamed,
    ).timeout(const Duration(seconds: 100));
    _check(response);
    final text =
        (jsonDecode(response.body) as Map)['text']?.toString().trim() ?? '';
    if (text.isEmpty)
      throw const VoiceException(
        'Não reconheci uma fala. Grave novamente ou escreva sua mensagem.',
      );
    return text;
  }

  @override
  Future<Uint8List> speech(int messageId) async {
    final response = await _client
        .post(
          _uri('speech'),
          headers: {
            ..._headers,
            'Content-Type': 'application/json',
            'Accept': 'audio/wav',
          },
          body: jsonEncode({'message_id': messageId}),
        )
        .timeout(const Duration(seconds: 100));
    _check(response);
    if (response.bodyBytes.length < 44 ||
        ascii.decode(response.bodyBytes.take(4).toList(), allowInvalid: true) !=
            'RIFF') {
      throw const VoiceException(
        'A resposta está disponível em texto, mas o áudio não pôde ser preparado.',
      );
    }
    return response.bodyBytes;
  }

  void _check(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String? message;
    try {
      message = (jsonDecode(response.body) as Map)['message']?.toString();
    } catch (_) {}
    throw VoiceException(
      message ?? 'Não foi possível processar o áudio. Tente novamente.',
    );
  }

  @override
  void close() => _client.close();
}
