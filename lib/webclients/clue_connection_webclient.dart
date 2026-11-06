import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:unisinos_usp_app/models/clue_connection_model.dart';
import 'package:widgets_spo/services/services.dart';

import 'webclient.dart';

class ClueConnectionWebclient {
  final WebClient webClient = WebClient.instance;

  String get endpoint => 'clue_connections';

  Future<List<ClueConnectionModel>> fetch() async {
    final Response response = await webClient.get(
      '/$endpoint',
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
      {},
    );

    return ClueConnectionModel.fromJsonArray(response.body);
  }

  Future<ClueConnectionModel> fetchById(int id) async {
    final Response response = await webClient.get(
      '/$endpoint/$id',
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
      {},
    );

    return ClueConnectionModel.fromJson(jsonDecode(response.body));
  }

  Future<ClueConnectionModel> create(ClueConnectionModel model) async {
    final Response response = await webClient.post(
      '/$endpoint',
      jsonEncode(model.toJson()),
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
    );

    return ClueConnectionModel.fromJson(jsonDecode(response.body));
  }

  Future<ClueConnectionModel> update(ClueConnectionModel model) async {
    final Response response = await webClient.put(
      '/$endpoint/${model.id}',
      jsonEncode(model.toJson()),
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
    );

    return ClueConnectionModel.fromJson(jsonDecode(response.body));
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
