import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:widgets_spo/services/auth_provider.dart';
import 'package:widgets_spo/services/interceptors/token_interceptor.dart';
import 'package:unisinos_usp_app/services/auth_user.dart';
import 'package:unisinos_usp_app/services/user_auth_service.dart';
import 'package:unisinos_usp_app/webclients/fauna_webclient.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';

void main() {
  test('fauna uses configured USP API, query parameters and user bearer',
      () async {
    AuthProvider.register(UserAuthService()
      ..setUser(const AuthUser(
          id: 1,
          name: 'Teste',
          email: 'test@example.test',
          token: 'synthetic')));
    // widgets_spo bypasses interceptors under FLUTTER_TEST. Verify the normal
    // token interceptor separately from the transport contract below.
    final authorized = await TokenInterceptor().interceptRequest(
        request: http.Request(
            'GET', Uri.parse('${WebClient.apiBaseUrl}/biodiversity/nearby')));
    expect(authorized.headers['Authorization'], 'Bearer synthetic');
    final original = WebClient.instance.client;
    addTearDown(() => WebClient.instance.client = original);
    final requests = <http.Request>[];
    WebClient.instance.client = MockClient((request) async {
      requests.add(request);
      expect(request.url.host, Uri.parse(WebClient.apiBaseUrl).host);

      return http.Response(jsonEncode({'observations': []}), 200);
    });
    await FaunaWebclient().nearby(-29.794, -51.151, 1000);
    await FaunaWebclient().bounds(LatLngBounds(
        const LatLng(-29.81, -51.17), const LatLng(-29.78, -51.13)));
    expect(requests[0].url.path, '/api/biodiversity/nearby');
    expect(requests[0].url.queryParameters,
        {'latitude': '-29.794', 'longitude': '-51.151', 'radius_m': '1000'});
    expect(requests[1].url.path, '/api/biodiversity/observations');
    expect(requests[1].url.queryParameters, {
      'north': '-29.78',
      'south': '-29.81',
      'east': '-51.13',
      'west': '-51.17'
    });
    WebClient.instance.client =
        MockClient((_) async => http.Response('Not found', 404));
    await expectLater(FaunaWebclient().nearby(0, 0, 1000), throwsException);
  });
}
