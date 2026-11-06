import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:unisinos_usp_app/models/sample_model.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:widgets_spo/services/services.dart';

class SampleWebclient {
  final WebClient webClient = WebClient.instance;

  String get endpoint => 'sample_models';

  Future<List<SampleModel>> fetch() async {
    final Response response = await webClient.get(
      '/$endpoint',
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
      {},
    );

    return SampleModel.fromJsonArray(response.body);
  }

  Future<SampleModel> fetchById(int id) async {
    final Response response = await webClient.get(
      '/$endpoint/$id',
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
      {},
    );

    return SampleModel.fromJson(jsonDecode(response.body));
  }

  Future<SampleModel> create(SampleModel model) async {
    final Response response = await webClient.post(
      '/$endpoint',
      jsonEncode(model.toJson()),
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
    );

    // The legacy create endpoint supplies server defaults for date, detail and
    // number. Apply the user's complete form through its supported update API.
    final created = SampleModel.fromJson(jsonDecode(response.body));
    model.id = created.id;
    try {
      return await update(model);
    } catch (_) {
      await delete(created.id);
      rethrow;
    }
  }

  Future<SampleModel> update(SampleModel model) async {
    final Response response = await webClient.put(
      '/$endpoint/${model.id}',
      jsonEncode(model.toJson()),
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
    );

    return SampleModel.fromJson(jsonDecode(response.body));
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
