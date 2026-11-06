import 'dart:convert';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:widgets_spo/services/services.dart';

/// HTTP failures must not navigate to home over an authentication redirect.
class AppApiInterceptor extends ApiInterceptor {
  @override
  Future<BaseResponse> interceptResponse(
      {required BaseResponse response}) async {
    // InterceptedClient.send requires a StreamedResponse; leave successful
    // streams untouched so the multipart caller can consume them exactly once.
    if (response.statusCode < 400) return response;
    final resolved = response is StreamedResponse
        ? await Response.fromStream(response)
        : response;
    String message = resolved.statusCode == 404
        ? 'Registro não encontrado.'
        : 'Não foi possível concluir a solicitação.';
    if (resolved is Response) {
      try {
        final body = jsonDecode(resolved.body);
        if (body is Map && body['message'] is String) message = body['message'];
      } catch (_) {/* HTML/proxy failures do not become JSON parsing errors. */}
    }
    if (resolved.statusCode == 401 &&
        message.toLowerCase().contains('você não está logado')) {
      await AuthProvider.instance.logout();
    }
    return Future.error(message);
  }
}
