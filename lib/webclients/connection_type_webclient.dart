import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:unisinos_usp_app/models/connection_type_model.dart';
import 'package:widgets_spo/services/services.dart';
import 'package:widgets_spo/widgets_spo.dart';

import 'webclient.dart';

class ConnectionTypeWebclient {
  final WebClient webClient = WebClient.instance;

  String get endpoint => 'connection_types';

  Future<List<ConnectionTypeModel>> fetch() async {
    final Response response = await webClient.get(
      '/$endpoint',
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
      {},
    );

    return ConnectionTypeModel.fromJsonArray(response.body);
  }

  Future<ConnectionTypeModel> fetchById(int id) async {
    final Response response = await webClient.get(
      '/$endpoint/$id',
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
      {},
    );

    return ConnectionTypeModel.fromJson(jsonDecode(response.body));
  }

  Future<ConnectionTypeModel> create(ConnectionTypeModel model) async {
    final Response response = await webClient.post(
      '/$endpoint',
      jsonEncode(model.toJson()),
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
    );

    return ConnectionTypeModel.fromJson(jsonDecode(response.body));
  }

  Future<ConnectionTypeModel> update(ConnectionTypeModel model) async {
    final Response response = await webClient.put(
      '/$endpoint/${model.id}',
      jsonEncode(model.toJson()),
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
    );

    return ConnectionTypeModel.fromJson(jsonDecode(response.body));
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

  Future<List<ItemSelect>?> select(String? search, int? offset) async {
    final Response response = await webClient.get(
      '/${endpoint}_select',
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
      {
        'limit': webClient.defaultLimit.toString(),
        'search': search ?? '',
        'offset': offset?.toString() ?? '0',
      },
    );

    final List<ItemSelect> returnList = ItemSelect.fromJsonArray(response.body.trim() == 'null' ? '[]' : response.body);
    return returnList.isEmpty ? null : returnList;
  }
}
