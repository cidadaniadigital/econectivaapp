import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:unisinos_usp_app/models/node_link_model.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:widgets_spo/services/services.dart';

class NodeLinkWebclient {
  final WebClient webClient = WebClient.instance;

  String get endpoint => 'node_links';

  Future<List<NodeLinkModel>> fetch({
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

    return NodeLinkModel.fromResponseBody(response.body);
  }

  Future<NodeLinkModel> fetchById(int id) async {
    final Response response = await webClient.get('/$endpoint/$id', _interceptors, {});
    return NodeLinkModel.fromJson(_extractObject(jsonDecode(response.body), 'node_link'));
  }

  Future<NodeLinkModel> create(NodeLinkModel model) async {
    final Response response = await webClient.post(
      '/$endpoint',
      jsonEncode({
        'source_node_id': model.sourceNodeId,
        'target_node_id': model.targetNodeId,
      }),
      _interceptors,
    );
    return NodeLinkModel.fromJson(_extractObject(jsonDecode(response.body), 'node_link'));
  }

  Future<NodeLinkModel> update(NodeLinkModel model) async {
    final Response response = await webClient.put(
      '/$endpoint/${model.id}',
      jsonEncode({
        'source_node_id': model.sourceNodeId,
        'target_node_id': model.targetNodeId,
      }),
      _interceptors,
    );
    return NodeLinkModel.fromJson(_extractObject(jsonDecode(response.body), 'node_link'));
  }

  Future<void> delete(int id) async {
    await webClient.delete('/$endpoint/$id', _interceptors);
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
    throw Exception('Resposta inválida ao processar ligação de nós.');
  }
}
