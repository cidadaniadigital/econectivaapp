import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:unisinos_usp_app/models/node_type_model.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:widgets_spo/services/services.dart';
import 'package:widgets_spo/widgets_spo.dart';

class NodeTypeWebclient {
  final WebClient webClient = WebClient.instance;

  String get endpoint => 'node_types';

  Future<List<NodeTypeModel>> fetch({
    int? limit,
    int offset = 0,
    String? search,
  }) async {
    final Response response = await webClient.get(
      '/$endpoint',
      _interceptors,
      {
        if (limit != null) 'limit': limit.toString(),
        'offset': offset.toString(),
        if (search != null) 'search': search,
      },
    );

    return NodeTypeModel.fromResponseBody(response.body);
  }

  Future<NodeTypeModel> fetchById(int id) async {
    final Response response = await webClient.get('/$endpoint/$id', _interceptors, {});
    return NodeTypeModel.fromJson(_extractObject(jsonDecode(response.body), 'node_type'));
  }

  Future<NodeTypeModel> create(NodeTypeModel model) async {
    final Response response = await webClient.post(
      '/$endpoint',
      jsonEncode({
        'name': model.name.trim(),
        'color': model.color.trim(),
      }),
      _interceptors,
    );
    return NodeTypeModel.fromJson(_extractObject(jsonDecode(response.body), 'node_type'));
  }

  Future<NodeTypeModel> update(NodeTypeModel model) async {
    final Response response = await webClient.put(
      '/$endpoint/${model.id}',
      jsonEncode({
        'name': model.name.trim(),
        'color': model.color.trim(),
      }),
      _interceptors,
    );
    return NodeTypeModel.fromJson(_extractObject(jsonDecode(response.body), 'node_type'));
  }

  Future<void> delete(int id) async {
    await webClient.delete('/$endpoint/$id', _interceptors);
  }

  Future<List<ItemSelect>?> select(String? search, int? offset) async {
    final List<NodeTypeModel> items = await fetch(
      search: search,
      offset: offset ?? 0,
      limit: webClient.defaultLimit,
    );
    if (items.isEmpty) return null;
    return items.map((item) => ItemSelect(id: item.id, name: item.name)).toList();
  }

  List<InterceptorContract> get _interceptors => [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ];

  Map<String, dynamic> _extractObject(dynamic decoded, String key) {
    if (decoded is Map<String, dynamic>) {
      if (decoded[key] is Map<String, dynamic>) return decoded[key] as Map<String, dynamic>;
      return decoded;
    }
    throw Exception('Resposta inválida ao processar tipo de nó.');
  }
}
