import 'dart:convert';

import 'package:unisinos_usp_app/models/territory_model.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class TerritoryWebclient {
  final WebClient webClient = WebClient.instance;
  String get endpoint => 'territories';

  Future<List<TerritoryModel>> fetch({int? biomeId}) async {
    final response = await webClient.get(
      '/$endpoint',
      [LoggingInterceptor(), ApiInterceptor(), TokenInterceptor()],
      {if (biomeId != null) 'biome_id': biomeId.toString()},
    );
    return TerritoryModel.fromJsonString(response.body);
  }

  Future<TerritoryModel> fetchById(int id) async {
    final response = await webClient.get('/$endpoint/$id', [
      LoggingInterceptor(),
      ApiInterceptor(),
      TokenInterceptor(),
    ], {});
    return TerritoryModel.fromJson(jsonDecode(response.body));
  }

  Future<TerritoryModel> create(TerritoryModel model) async {
    final response = await webClient.post(
      '/$endpoint',
      jsonEncode(model.toJson()),
      [LoggingInterceptor(), ApiInterceptor(), TokenInterceptor()],
    );
    return TerritoryModel.fromJson(jsonDecode(response.body));
  }

  Future<TerritoryModel> update(TerritoryModel model) async {
    final response = await webClient.put(
      '/$endpoint/${model.id}',
      jsonEncode(model.toJson()),
      [LoggingInterceptor(), ApiInterceptor(), TokenInterceptor()],
    );
    return TerritoryModel.fromJson(jsonDecode(response.body));
  }

  Future<void> delete(int id) async {
    await webClient.delete('/$endpoint/$id', [
      LoggingInterceptor(),
      ApiInterceptor(),
      TokenInterceptor(),
    ]);
  }

  Future<List<ItemSelect>?> select(
    String? search,
    int? offset, {
    int? biomeId,
  }) async {
    final response = await webClient.get(
      '/${endpoint}_select',
      [LoggingInterceptor(), ApiInterceptor(), TokenInterceptor()],
      {
        'limit': webClient.defaultLimit.toString(),
        'search': search ?? '',
        'offset': offset?.toString() ?? '0',
        if (biomeId != null) 'biome_id': biomeId.toString(),
      },
    );
    final list = ItemSelect.fromJsonArray(response.body.trim() == 'null' ? '[]' : response.body);
    return list.isEmpty ? null : list;
  }
}
