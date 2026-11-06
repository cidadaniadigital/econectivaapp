import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:unisinos_usp_app/models/category_model.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:widgets_spo/services/services.dart';

class CategoryWebclient {
  final WebClient webClient = WebClient.instance;

  String get endpoint => 'categories';

  Future<List<CategoryModel>> fetch() async {
    final Response response = await webClient.get(
      '/$endpoint',
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
      {},
    );

    return CategoryModel.fromJsonArray(jsonDecode(response.body));
  }

  Future<CategoryModel> fetchById(int id) async {
    final Response response = await webClient.get(
      '/$endpoint/$id',
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
      {},
    );

    return CategoryModel.fromJson(jsonDecode(response.body));
  }

  Future<CategoryModel> create(CategoryModel category) async {
    final Response response = await webClient.post(
      '/$endpoint',
      jsonEncode(category.toJson()),
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
    );

    return CategoryModel.fromJson(jsonDecode(response.body));
  }

  Future<CategoryModel> update(CategoryModel category) async {
    if (category.id <= 0)
      throw Exception('Categoria sem ID não pode ser atualizada');

    final Response response = await webClient.put(
      '/$endpoint/${category.id}',
      jsonEncode(category.toJson()),
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
    );

    return CategoryModel.fromJson(jsonDecode(response.body));
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
