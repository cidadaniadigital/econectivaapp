import 'package:widgets_spo/services/webclient_base.dart';
import 'dart:convert';
import 'app_api_interceptor.dart';
import 'package:widgets_spo/models/mfile_base_model.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:widgets_spo/services/services.dart';

class WebClient extends WebClientBase {
  @override
  String get host => Uri.parse(apiBaseUrl).host;

  static final WebClient _instance = WebClient._();

  WebClient._();

  static WebClient get instance => _instance;

  // Default remains production; previews can use an isolated API without edits.
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'https://api.atopos.spotec.app/api');

  List<InterceptorContract> _configured(
          List<InterceptorContract>? interceptors) =>
      [
        _ApiAddressInterceptor(),
        ...?interceptors
            ?.where((item) => item is! LoggingInterceptor)
            .map((item) => item is ApiInterceptor ? AppApiInterceptor() : item)
      ];

  @override
  Future<Response> get(String uri, List<InterceptorContract>? interceptors,
          Map<String, dynamic>? queryParameters, {int? timeOut}) =>
      super.get(uri, _configured(interceptors), queryParameters,
          timeOut: timeOut);

  @override
  Future<Response> post(
          String uri, String body, List<InterceptorContract>? interceptors,
          {int? timeOut}) =>
      super.post(uri, body, _configured(interceptors), timeOut: timeOut);

  @override
  Future<Response> put(
          String uri, String body, List<InterceptorContract>? interceptors,
          {int? timeOut}) =>
      super.put(uri, body, _configured(interceptors), timeOut: timeOut);

  @override
  Future<Response> patch(
          String uri, String body, List<InterceptorContract>? interceptors,
          {int? timeOut}) =>
      super.patch(uri, body, _configured(interceptors), timeOut: timeOut);

  @override
  Future<Response> delete(String uri, List<InterceptorContract>? interceptors,
          {int? timeOut}) =>
      super.delete(uri, _configured(interceptors), timeOut: timeOut);

  @override
  Future<Response> postMultipart(
          String uri, MFileBase file, List<InterceptorContract> interceptors,
          {int? timeOut, Map<String, String?> fileFields = const {}}) =>
      super.postMultipart(uri, file, _configured(interceptors),
          timeOut: timeOut, fileFields: fileFields);
}

class _ApiAddressInterceptor extends InterceptorContract {
  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    final base = Uri.parse(WebClient.apiBaseUrl);
    final suffix = request.url.path.replaceFirst(RegExp(r'^/?api'), '');
    final url = base.replace(
      path: '${base.path.replaceFirst(RegExp(r'/$'), '')}$suffix',
      query: request.url.hasQuery ? request.url.query : null,
    );
    return request.copyWith(url: url);
  }

  @override
  Future<BaseResponse> interceptResponse(
      {required BaseResponse response}) async {
    if (response is Response &&
        response.statusCode == 403 &&
        response.body.contains('Escolha o modo Inventor')) {
      return response.copyWith(
          body: jsonEncode({
        'message':
            'Ative criação e edição em Meu perfil para alterar conteúdos.'
      }));
    }
    return response;
  }
}
