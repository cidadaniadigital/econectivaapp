import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:unisinos_usp_app/models/node_map_model.dart';
import 'package:unisinos_usp_app/models/node_model.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:widgets_spo/services/services.dart';
import 'package:widgets_spo/widgets_spo.dart';

class NodeWebclient {
  final WebClient webClient = WebClient.instance;

  String get endpoint => 'nodes';

  Future<List<NodeModel>> fetch({
    int? limit,
    int offset = 0,
    String? search,
    int? nodeTypeId,
  }) async {
    final Response response = await webClient.get(
      '/$endpoint',
      _interceptors,
      {
        if (limit != null) 'limit': limit.toString(),
        'offset': offset.toString(),
        if (search != null) 'search': search,
        if (nodeTypeId != null) 'node_type_id': nodeTypeId.toString(),
      },
    );

    return NodeModel.fromResponseBody(response.body);
  }

  Future<NodeModel> fetchById(int id) async {
    final Response response =
        await webClient.get('/$endpoint/$id', _interceptors, {});
    return NodeModel.fromJson(
        _extractObject(jsonDecode(response.body), 'node'));
  }

  Future<NodeModel> create(NodeModel model) async {
    final Response response = await webClient.post(
      '/$endpoint',
      jsonEncode({
        'name': model.name.trim(),
        'color': model.color.trim(),
        'node_type_id': model.nodeTypeId,
        'x': model.x,
        'y': model.y,
      }),
      _interceptors,
    );
    return NodeModel.fromJson(
        _extractObject(jsonDecode(response.body), 'node'));
  }

  Future<NodeModel> update(NodeModel model) async {
    final Response response = await webClient.put(
      '/$endpoint/${model.id}',
      jsonEncode({
        'name': model.name.trim(),
        'color': model.color.trim(),
        'node_type_id': model.nodeTypeId,
        'x': model.x,
        'y': model.y,
      }),
      _interceptors,
    );
    return NodeModel.fromJson(
        _extractObject(jsonDecode(response.body), 'node'));
  }

  Future<void> delete(int id) async {
    await webClient.delete('/$endpoint/$id', _interceptors);
  }

  Future<NodeMapModel> fetchMap() async {
    final Response response =
        await webClient.get('/$endpoint/map', _interceptors, {});
    return NodeMapModel.fromResponseBody(response.body);
  }

  Future<List<ItemSelect>?> select(String? search, int? offset) async {
    final List<NodeModel> items = await fetch(
      search: search,
      offset: offset ?? 0,
      limit: webClient.defaultLimit,
    );
    if (items.isEmpty) return null;
    return items
        .map((item) => ItemSelect(id: item.id, name: item.name))
        .toList();
  }

  List<InterceptorContract> get _interceptors => [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ];

  Map<String, dynamic> _extractObject(dynamic decoded, String key) {
    if (decoded is Map<String, dynamic>) {
      if (decoded[key] is Map<String, dynamic>) {
        return decoded[key] as Map<String, dynamic>;
      }
      return decoded;
    }
    throw Exception('Resposta inválida ao processar nó.');
  }
}
