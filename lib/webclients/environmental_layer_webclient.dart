import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:unisinos_usp_app/models/environmental_layer_model.dart';
import 'package:widgets_spo/services/services.dart';

import 'package:unisinos_usp_app/webclients/webclient.dart';

class EnvironmentalLayerWebclient {
  final WebClient webClient = WebClient.instance;

  Future<List<EnvironmentalLayerModel>> fetch() async {
    final Response response = await webClient.get(
      '/environmental_layers',
      [LoggingInterceptor(), ApiInterceptor(), TokenInterceptor()],
      {},
    );
    final values = jsonDecode(response.body) as List<dynamic>;
    return values
        .whereType<Map<String, dynamic>>()
        .map(EnvironmentalLayerModel.fromJson)
        .toList();
  }

  String absoluteTileUrl(EnvironmentalLayerModel layer) {
    // Tiles always go through our authenticated proxy, never an external host.
    final prefix = '/api/environmental_tiles/${layer.id}/';
    if (!layer.tileUrl.startsWith(prefix) ||
        layer.tileUrl.contains('..') ||
        layer.tileUrl.contains('?') ||
        layer.tileUrl.contains('#')) {
      throw const FormatException('Endereço de camada inválido');
    }
    return '${WebClient.apiBaseUrl.replaceFirst(RegExp(r"/$"), "")}'
        '${layer.tileUrl.substring(4)}';
  }
}
