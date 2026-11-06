import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:unisinos_usp_app/models/chat_message_model.dart';
import 'package:unisinos_usp_app/models/chat_template_model.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:widgets_spo/services/services.dart';

class ChatTemplateWebclient {
  final WebClient webClient = WebClient.instance;

  String get endpoint => 'chat_templates';

  Future<List<ChatTemplateModel>> fetch({
    int limit = 20,
    int offset = 0,
    String? search,
  }) async {
    final Response response = await webClient.get(
      '/$endpoint',
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
      {
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (search != null) 'search': search,
      },
    );

    return ChatTemplateModel.fromResponseBody(response.body);
  }

  Future<ChatTemplateModel> fetchById(int id) async {
    final response = await webClient
        .get('/$endpoint/$id', [ApiInterceptor(), TokenInterceptor()], {});
    return ChatTemplateModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<ChatTemplateModel> create(ChatTemplateModel model) async {
    final Response response = await webClient.post(
      '/$endpoint',
      jsonEncode(model.toJson()),
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
    );

    final dynamic decoded = jsonDecode(response.body);
    final Map<String, dynamic> payload = (decoded is Map<String, dynamic> &&
            decoded['chat_template'] is Map<String, dynamic>)
        ? decoded['chat_template'] as Map<String, dynamic>
        : decoded as Map<String, dynamic>;
    return ChatTemplateModel.fromJson(payload);
  }

  Future<ChatTemplateModel> update(ChatTemplateModel model) async {
    final Response response = await webClient.put(
      '/$endpoint/${model.id}',
      jsonEncode(model.toJson()),
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
    );
    return _parseTemplateFromResponse(response.body);
  }

  ChatTemplateModel _parseTemplateFromResponse(String body) {
    final dynamic decoded = jsonDecode(body);
    final Map<String, dynamic> payload = (decoded is Map<String, dynamic> &&
            decoded['chat_template'] is Map<String, dynamic>)
        ? decoded['chat_template'] as Map<String, dynamic>
        : decoded as Map<String, dynamic>;
    return ChatTemplateModel.fromJson(payload);
  }

  Future<void> delete(int id) async {
    await webClient.delete(
      '/$endpoint/$id',
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
    );
  }

  Future<List<ChatMessageModel>> fetchMessages(
    int templateId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final Response response = await webClient.get(
      '/$endpoint/$templateId/messages',
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
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

    final List<ChatMessageModel> messages = items
        .whereType<Map<String, dynamic>>()
        .map(ChatMessageModel.fromHistoryJson)
        .toList();

    messages.sort((a, b) {
      final int timestampComparison = a.timestamp.compareTo(b.timestamp);
      if (timestampComparison != 0) return timestampComparison;
      return (a.id ?? 0).compareTo(b.id ?? 0);
    });
    return messages;
  }

  Future<void> deleteAllMessages(int templateId) async {
    await webClient.delete(
      '/$endpoint/$templateId/messages',
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
    );
  }

  Future<List<ChatMessageModel>> sendMessage(
      int templateId, String content) async {
    final Response response = await webClient.post(
      '/$endpoint/$templateId/messages',
      jsonEncode({'message': content}),
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
    );

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is List<dynamic>) {
      final List<ChatMessageModel> sentMessages = decoded
          .whereType<Map<String, dynamic>>()
          .map(ChatMessageModel.fromHistoryJson)
          .toList();
      if (sentMessages.isNotEmpty) {
        sentMessages.sort((a, b) {
          final int timestampComparison = a.timestamp.compareTo(b.timestamp);
          if (timestampComparison != 0) return timestampComparison;
          return (a.id ?? 0).compareTo(b.id ?? 0);
        });
        return sentMessages;
      }
    }

    if (decoded is Map<String, dynamic>) {
      final Map<String, dynamic> payload =
          (decoded['message'] is Map<String, dynamic>)
              ? decoded['message'] as Map<String, dynamic>
              : decoded;
      return <ChatMessageModel>[ChatMessageModel.fromHistoryJson(payload)];
    }

    throw Exception('Resposta inválida ao enviar mensagem.');
  }
}
