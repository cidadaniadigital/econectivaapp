import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:widgets_spo/services/services.dart';
import 'package:widgets_spo/widgets_spo.dart';

import 'webclient.dart';

class LivingClueWebclient {
  final WebClient webClient = WebClient.instance;

  String get endpoint => 'living_clues';

  Future<List<LivingClueModel>> fetch({
    String search = '',
    int? limit,
    int offset = 0,
    int? categoryId,
  }) async {
    final Response response = await webClient.get(
      '/$endpoint',
      [LoggingInterceptor(), ApiInterceptor(), TokenInterceptor()],
      {
        'search': search,
        'offset': offset.toString(),
        if (limit != null) 'limit': limit.toString(),
        if (categoryId != null) 'category_id': categoryId.toString(),
      },
    );

    return LivingClueModel.fromJsonArray(response.body);
  }

  Future<List<LivingClueModel>> fetchByBounds({
    required double north,
    required double south,
    required double east,
    required double west,
    int? limit,
    int? categoryId,
  }) async {
    final Response response = await webClient.get(
      '/$endpoint',
      [LoggingInterceptor(), ApiInterceptor(), TokenInterceptor()],
      {
        'north': north.toString(),
        'south': south.toString(),
        'east': east.toString(),
        'west': west.toString(),
        'limit': (limit ?? webClient.defaultLimit).toString(),
        if (categoryId != null) 'category_id': categoryId.toString(),
      },
    );

    return LivingClueModel.fromJsonArray(response.body);
  }

  Future<List<LivingClueModel>> searchByRadius({
    required double latitude,
    required double longitude,
    required double radiusMeters,
    int? limit,
    int? categoryId,
  }) async {
    final Response response = await webClient.get(
      '/$endpoint',
      [LoggingInterceptor(), ApiInterceptor(), TokenInterceptor()],
      {
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'radius': radiusMeters.toString(),
        'limit': (limit ?? webClient.defaultLimit).toString(),
        if (categoryId != null) 'category_id': categoryId.toString(),
      },
    );

    return LivingClueModel.fromJsonArray(response.body);
  }

  Future<LivingClueModel> fetchById(int id) async {
    final Response response = await webClient.get('/$endpoint/$id', [
      LoggingInterceptor(),
      ApiInterceptor(),
      TokenInterceptor(),
    ], {});
    return LivingClueModel.fromJson(jsonDecode(response.body));
  }

  Future<LivingClueModel> create(LivingClueModel model) async {
    final Response response = await webClient.post(
      '/$endpoint',
      jsonEncode(model.toJson()),
      [LoggingInterceptor(), ApiInterceptor(), TokenInterceptor()],
    );
    return LivingClueModel.fromJson(jsonDecode(response.body));
  }

  Future<LivingClueModel> update(LivingClueModel model) async {
    final Response response = await webClient.put(
      '/$endpoint/${model.id}',
      jsonEncode(model.toJson()),
      [LoggingInterceptor(), ApiInterceptor(), TokenInterceptor()],
    );
    return LivingClueModel.fromJson(jsonDecode(response.body));
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
    int? categoryId,
  }) async {
    final Response response = await webClient.get(
      '/${endpoint}_select',
      [LoggingInterceptor(), ApiInterceptor(), TokenInterceptor()],
      {
        'limit': webClient.defaultLimit.toString(),
        'search': search ?? '',
        'offset': offset?.toString() ?? '0',
        if (categoryId != null) 'category_id': categoryId.toString(),
      },
    );

    final List<ItemSelect> returnList = ItemSelect.fromJsonArray(
        response.body.trim() == 'null' ? '[]' : response.body);
    return returnList.isEmpty ? null : returnList;
  }
}
