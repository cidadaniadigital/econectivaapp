import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:widgets_spo/services/auth_provider.dart';
import 'package:unisinos_usp_app/services/auth_user.dart';
import 'package:unisinos_usp_app/services/user_auth_service.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/webclients/deter_webclient.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:unisinos_usp_app/widgets/clue_observations.dart';
import 'package:unisinos_usp_app/widgets/deter_nearby.dart';
import 'package:unisinos_usp_app/widgets/fauna_nearby.dart';
import 'deter_nearby_test.dart' show notices;

void main() {
  late http.Client original;
  final requests = <Uri>[];
  setUp(() {
    original = WebClient.instance.client;
    requests.clear();
    AuthProvider.register(UserAuthService()
      ..setUser(const AuthUser(
          id: 1,
          name: 'Teste',
          email: 'test@example.test',
          token: 'synthetic')));
    WebClient.instance.client = MockClient((request) async {
      requests.add(request.url);
      if (request.url.path.endsWith('/deter/nearby')) {
        return http.Response(jsonEncode(notices()), 200);
      }
      if (request.url.path.contains('/biodiversity/')) {
        return http.Response('{"observations":[]}', 200);
      }
      return http.Response('[]', 200);
    });
  });
  tearDown(() => WebClient.instance.client = original);
  test('DETER uses configured USP API route, radius and coordinates', () async {
    final result =
        await DeterWebclient().nearby(-1.60820485, -55.1604346, 5000);
    expect(result['total'], 2);
    final request = requests.single;
    expect(request.host, Uri.parse(WebClient.apiBaseUrl).host);
    expect(request.path, '/api/deter/nearby');
    expect(request.queryParameters, {
      'latitude': '-1.60820485',
      'longitude': '-55.1604346',
      'radius_m': '5000'
    });
    WebClient.instance.client =
        MockClient((_) async => http.Response('Not found', 404));
    await expectLater(DeterWebclient().nearby(0, 0, 1000), throwsException);
    WebClient.instance.client =
        MockClient((_) async => http.Response('invalid json', 200));
    await expectLater(
        DeterWebclient().nearby(0, 0, 1000), throwsFormatException);
  });
  for (final located in [false, true]) {
    testWidgets(
        'USP context renders optional DETER and fauna only with location $located',
        (tester) async {
      final clue = LivingClueModel(
          id: 59,
          name: 'Pista',
          categoryId: 1,
          latitude: located ? -1.6 : null,
          longitude: located ? -55.16 : null);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body:
                  SingleChildScrollView(child: ClueObservations(clue: clue)))));
      await tester.pumpAndSettle();
      expect(find.byType(DeterNearby), located ? findsOneWidget : findsNothing);
      expect(find.byType(FaunaNearby), located ? findsOneWidget : findsNothing);
      expect(requests.where((r) => r.path.endsWith('/deter/nearby')).length,
          located ? 1 : 0);
      if (located) {
        expect(find.text('Contexto ambiental indisponível.'), findsOneWidget);
        expect(find.textContaining('2 avisos no entorno'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
