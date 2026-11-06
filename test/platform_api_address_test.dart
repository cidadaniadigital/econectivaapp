import 'dart:convert';
import 'package:widgets_spo/services/auth_provider.dart';
import 'package:unisinos_usp_app/services/user_auth_service.dart';
import 'package:unisinos_usp_app/services/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:unisinos_usp_app/webclients/environmental_layer_webclient.dart';
import 'package:unisinos_usp_app/services/iarete_voice/voice_api.dart';

void main() {
  test('Atopos catalog and audio use the isolated API without touching OnLIFE',
      () async {
    final auth = UserAuthService()
      ..setUser(const AuthUser(
          id: 1,
          name: 'Teste',
          email: 'test@example.test',
          token: 'synthetic'));
    AuthProvider.register(auth);
    final original = WebClient.instance.client;
    addTearDown(() => WebClient.instance.client = original);
    final requests = <Uri>[];
    WebClient.instance.client = MockClient((request) async {
      requests.add(request.url);
      return http.Response(jsonEncode([]), 200);
    });
    await EnvironmentalLayerWebclient().fetch();
    expect(requests, isNotEmpty);
    for (final uri in requests) {
      expect(uri.host, 'api.atopos.spotec.app');
      expect(uri.path, startsWith('/api/'));
    }
    final voice = IareteVoiceApi(client: MockClient((request) async {
      expect(request.url.host, 'api.atopos.spotec.app');
      return http.Response('{"message":"teste"}', 503);
    }));
    addTearDown(voice.close);
    await expectLater(voice.speech(1), throwsA(isA<VoiceException>()));
  });
}
