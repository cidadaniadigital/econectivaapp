import 'dart:convert';

import 'package:http/http.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:unisinos_usp_app/models/file_model.dart';
import 'package:widgets_spo/widgets_spo.dart';

import 'package:unisinos_usp_app/webclients/webclient.dart';

class FileWebclient {
  final WebClient webClient = WebClient.instance;

  String get endpoint => 'files';

  Future<List<FileModel>> fetch({int? livingClueId}) async {
    final Response response = await webClient.get(
      '/$endpoint',
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
      {
        if (livingClueId != null) 'living_clue_id': livingClueId.toString(),
      },
    );

    return FileModel.fromJsonArray(response.body);
  }

  Future<FileModel> upload(FileModel model) async {
    final uploaded = await webClient.postMultipart(
      '/$endpoint',
      model,
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
      fileFields: {
        if (model.livingClueId != null)
          'living_clue_id': model.livingClueId.toString(),
        if (model.name != null) 'name': model.name,
        'extension': model.extension,
      },
    );
    return FileModel.fromJson(
        jsonDecode(uploaded.body) as Map<String, dynamic>);
  }

  Future<FileModel> uploadBase64({
    required String base64,
    required String extension,
    required String name,
    required String path,
  }) async {
    final Response response = await webClient.post(
      '/$endpoint',
      jsonEncode({
        'base_64': base64,
        'extension': extension,
        'name': name,
        'path': path,
      }),
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
    );
    return FileModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Uri> access(int id) async {
    final response = await webClient.get(
        '/$endpoint/$id/access', [ApiInterceptor(), TokenInterceptor()], {});
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final uri = Uri.tryParse(data['url']?.toString() ?? '');
    if (uri == null ||
        !{'https', 'http'}.contains(uri.scheme) ||
        uri.host.isEmpty) {
      throw const FormatException('Endereço do arquivo inválido');
    }
    return uri;
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

class AttachmentException implements Exception {
  const AttachmentException(this.message);
  final String message;
  @override String toString() => message;
}
