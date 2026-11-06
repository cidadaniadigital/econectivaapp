import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:unisinos_usp_app/models/ai_assistant_message_model.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:widgets_spo/services/services.dart';

class AiAssistantWebclient {
  final WebClient _webClient = WebClient.instance;

  Future<List<AiAssistantMessageModel>> fetchHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    final Response response = await _webClient.get(
      '/ai/messages',
      _interceptors,
      {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! List<dynamic>) return const <AiAssistantMessageModel>[];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(AiAssistantMessageModel.fromJson)
        .toList();
  }

  Future<List<AiAssistantMessageModel>> sendMessage({
    required String message,
    required String context,
    Map<String, dynamic>? screenContext,
  }) async {
    final Response response = await _webClient.post(
      '/ai/messages',
      jsonEncode({
        'message': message,
        'context': context,
        if (screenContext != null) 'screen_context': screenContext,
      }),
      _interceptors,
    );

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! List<dynamic>) {
      throw Exception('Resposta inválida do assistente.');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(AiAssistantMessageModel.fromJson)
        .toList();
  }

  List<InterceptorContract> get _interceptors => [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ];
}
