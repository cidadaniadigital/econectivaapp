import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:unisinos_usp_app/webclients/app_api_interceptor.dart';

void main() {
  test('permission failure remains an error without sending user home',
      () async {
    await expectLater(
        AppApiInterceptor().interceptResponse(
            response: Response('{"message":"Sem permissão"}', 401)),
        throwsA(isA<String>()));
  });
  test('proxy HTML failure does not crash JSON decoding', () async {
    await expectLater(
        AppApiInterceptor()
            .interceptResponse(response: Response('<html>failure</html>', 502)),
        throwsA(isA<String>()));
  });
  test(
      'successful multipart response remains a stream until the caller reads it',
      () async {
    final response = await AppApiInterceptor().interceptResponse(
        response:
            StreamedResponse(Stream.value(utf8.encode('{"id":10}')), 201));
    expect(response, isA<StreamedResponse>());
    expect((await Response.fromStream(response as StreamedResponse)).body,
        '{"id":10}');
  });
}
