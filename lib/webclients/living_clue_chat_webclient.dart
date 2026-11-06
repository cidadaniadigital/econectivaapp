import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:unisinos_usp_app/models/living_clue_chat_message_model.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:widgets_spo/services/services.dart';

class LivingClueChatWebclient {
  final WebClient webClient = WebClient.instance;

  Future<List<LivingClueChatMessageModel>> fetchMessages(
    int livingClueId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final Response response = await webClient.get(
      '/living_clues/$livingClueId/chat/messages',
      [LoggingInterceptor(), ApiInterceptor(), TokenInterceptor()],
      {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );

    final dynamic decoded = jsonDecode(response.body);
    final List<dynamic> items;
    if (decoded is List<dynamic>) {
      items = decoded;
    } else if (decoded is Map<String, dynamic>) {
      items = decoded['messages'] as List<dynamic>? ??
          decoded['data'] as List<dynamic>? ??
          const [];
    } else {
      items = const [];
    }

    final List<LivingClueChatMessageModel> messages = items
        .whereType<Map<String, dynamic>>()
        .map(LivingClueChatMessageModel.fromJson)
        .toList();

    messages.sort((a, b) {
      final int timestampComparison = a.timestamp.compareTo(b.timestamp);
      if (timestampComparison != 0) return timestampComparison;
      return (a.id ?? 0).compareTo(b.id ?? 0);
    });
    return messages;
  }

  Future<List<LivingClueChatMessageModel>> sendMessage(
      int livingClueId, String content) async {
    final Response response = await webClient.post(
      '/living_clues/$livingClueId/chat/messages',
      jsonEncode({'message': content}),
      [LoggingInterceptor(), ApiInterceptor(), TokenInterceptor()],
    );

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is List<dynamic>) {
      final List<LivingClueChatMessageModel> sentMessages = decoded
          .whereType<Map<String, dynamic>>()
          .map(LivingClueChatMessageModel.fromJson)
          .toList();
      sentMessages.sort((a, b) {
        final int timestampComparison = a.timestamp.compareTo(b.timestamp);
        if (timestampComparison != 0) return timestampComparison;
        return (a.id ?? 0).compareTo(b.id ?? 0);
      });
      return sentMessages;
    }

    if (decoded is Map<String, dynamic>) {
      return <LivingClueChatMessageModel>[
        LivingClueChatMessageModel.fromJson(decoded)
      ];
    }

    throw Exception('Resposta inválida ao enviar mensagem.');
  }

  Future<void> deleteAllMessages(int livingClueId) async {
    await webClient.delete(
      '/living_clues/$livingClueId/chat/messages',
      [LoggingInterceptor(), ApiInterceptor(), TokenInterceptor()],
    );
  }
}
