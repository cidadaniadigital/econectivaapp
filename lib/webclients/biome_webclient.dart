import 'dart:convert';

import 'package:unisinos_usp_app/models/biome_model.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class BiomeWebclient {
  final WebClient webClient = WebClient.instance;
  String get endpoint => 'biomes';

  Future<List<BiomeModel>> fetch() async {
    final response = await webClient.get('/$endpoint', [
      LoggingInterceptor(),
      ApiInterceptor(),
      TokenInterceptor(),
    ], {});
    return BiomeModel.fromJsonString(response.body);
  }

  Future<BiomeModel> fetchById(int id) async {
    final response = await webClient.get('/$endpoint/$id', [
      LoggingInterceptor(),
      ApiInterceptor(),
      TokenInterceptor(),
    ], {});
    return BiomeModel.fromJson(jsonDecode(response.body));
  }

  Future<BiomeModel> create(BiomeModel model) async {
    final response = await webClient.post(
      '/$endpoint',
      jsonEncode(model.toJson()),
      [LoggingInterceptor(), ApiInterceptor(), TokenInterceptor()],
    );
    return BiomeModel.fromJson(jsonDecode(response.body));
  }

  Future<BiomeModel> update(BiomeModel model) async {
    final response = await webClient.put(
      '/$endpoint/${model.id}',
      jsonEncode(model.toJson()),
      [LoggingInterceptor(), ApiInterceptor(), TokenInterceptor()],
    );
    return BiomeModel.fromJson(jsonDecode(response.body));
  }

  Future<void> delete(int id) async {
    await webClient.delete('/$endpoint/$id', [
      LoggingInterceptor(),
      ApiInterceptor(),
      TokenInterceptor(),
    ]);
  }

  Future<List<ItemSelect>?> select(String? search, int? offset) async {
    final response = await webClient.get(
      '/${endpoint}_select',
      [LoggingInterceptor(), ApiInterceptor(), TokenInterceptor()],
      {
        'limit': webClient.defaultLimit.toString(),
        'search': search ?? '',
        'offset': offset?.toString() ?? '0',
      },
    );
    final list = ItemSelect.fromJsonArray(response.body.trim() == 'null' ? '[]' : response.body);
    return list.isEmpty ? null : list;
  }
}
