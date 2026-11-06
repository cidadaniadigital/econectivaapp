import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/widgets/clue_observations.dart';

void main() {
  const channel = MethodChannel('plugins.flutter.io/url_launcher');
  for (final unsafe in [false, true]) {
    testWidgets(
        unsafe
            ? 'environmental catalog cannot expose executable source links'
            : 'source button opens catalog URL without replacing historical version',
        (tester) async {
      final launched = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'launch') {
          launched.add((call.arguments as Map)['url'] as String);
        }
        return true;
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null));
      final catalog = <Map<String, Object>>[
        {
          'id': 'biome-layer',
          'source': {
            'name': 'Catálogo atual',
            'version': 'v2',
            'url': unsafe ? 'javascript:alert(1)' : 'https://example.org/biome',
          },
        }
      ];
      final requested = <Uri>[];
      final previousClient = WebClient.instance.client;
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/environmental_layers');
        requested.add(request.url);
        return http.Response(jsonEncode(catalog), 200,
            headers: {'content-type': 'application/json'});
      });
      WebClient.instance.client = client;
      addTearDown(() {
        WebClient.instance.client = previousClient;
        client.close();
      });
      final clue = LivingClueModel.fromJson({
        'id': 8,
        'category_id': 1,
        'latitude': -29,
        'longitude': -51,
        'environmental_context': {
          'status': 'completed',
          'analyzed_latitude': -29,
          'analyzed_longitude': -51,
          'biome': 'Bioma demonstrativo',
          'sources': {
            'biome': {
              'dataset': 'Referência histórica',
              'version': 'v1',
              'layer_id': 'biome-layer',
            },
          },
        },
      });
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body:
                  SingleChildScrollView(child: ClueObservations(clue: clue)))));
      await tester.pumpAndSettle();
      expect(requested, hasLength(1));
      expect(find.text('Referência histórica • v1'), findsOneWidget);
      const label = 'Catálogo atual (versão diferente do snapshot)';
      if (unsafe) {
        expect(find.text(label), findsNothing);
        expect(launched, isEmpty);
      } else {
        expect(find.text(label), findsOneWidget);
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(launched, ['https://example.org/biome']);
        expect(find.text('Referência histórica • v1'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
