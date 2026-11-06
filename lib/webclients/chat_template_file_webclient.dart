import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:unisinos_usp_app/models/chat_template_model.dart';
import 'package:unisinos_usp_app/models/file_model.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:widgets_spo/services/services.dart';

class ChatTemplateFileWebclient {
  final WebClient webClient = WebClient.instance;

  String get endpoint => 'chat_template_files';

  Future<List<ChatTemplateFileModel>> fetch({
    required int chatTemplateId,
  }) async {
    final Response response = await webClient.get(
      '/$endpoint',
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
      {'chat_template_id': chatTemplateId.toString()},
    );

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is List<dynamic>) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ChatTemplateFileModel.fromJson)
          .toList();
    }
    return const <ChatTemplateFileModel>[];
  }

  Future<ChatTemplateFileModel> create(ChatTemplateFileModel model) async {
    final Response response = await webClient.post(
      '/$endpoint',
      jsonEncode(model.toJson()),
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
    );

    return ChatTemplateFileModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ChatTemplateFileModel> upload({
    required int chatTemplateId,
    required String name,
    required String mimeType,
    required FileModel file,
  }) async {
    final response = await webClient.postMultipart('/$endpoint', file, [
      ApiInterceptor(),
      TokenInterceptor()
    ], fileFields: {
      'chat_template_id': chatTemplateId.toString(),
      'name': name,
      'type': 'file',
      'mime_type': mimeType,
    });
    return ChatTemplateFileModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<ChatTemplateFileModel> fetchById(int id) async {
    final Response response = await webClient.get(
      '/$endpoint/$id',
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
      const {},
    );
    return ChatTemplateFileModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
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
}
