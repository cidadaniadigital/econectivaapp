import 'dart:convert';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:widgets_spo/services/services.dart';

class EconectivaApi {
  final _client = WebClient.instance;
  final _interceptors = [
    LoggingInterceptor(),
    ApiInterceptor(),
    TokenInterceptor()
  ];
  Future<dynamic> get(String path,
      [Map<String, String> query = const {}]) async {
    final r = await _client.get(path, _interceptors, query);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('Não foi possível carregar os dados.');
    }
    return jsonDecode(r.body);
  }

  Future<dynamic> write(String method, String path,
      [Map<String, dynamic> body = const {}]) async {
    final r = method == 'POST'
        ? await _client.post(path, jsonEncode(body), _interceptors)
        : method == 'DELETE'
            ? await _client.delete(path, _interceptors)
            : await _client.put(path, jsonEncode(body), _interceptors);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('Não foi possível salvar a alteração.');
    }
    return jsonDecode(r.body);
  }
}
