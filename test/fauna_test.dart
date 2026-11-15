import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:unisinos_usp_app/controllers/living_clue/fauna_map_controller.dart';
import 'package:unisinos_usp_app/models/fauna_model.dart';
import 'package:unisinos_usp_app/webclients/fauna_webclient.dart';
import 'package:unisinos_usp_app/widgets/fauna_nearby.dart';

FaunaResult faunaResult(int id) => FaunaResult.fromJson({
      'observations': [
        {
          'id': id,
          'taxon_id': id,
          'scientific_name': 'Phimosus infuscatus',
          'common_name': 'Tapicuru $id',
          'latitude': -29.79,
          'longitude': -51.15,
          'photo_url': 'https://example.invalid/photo.jpg',
          'photo_license': 'cc-by',
          'photo_attribution': 'Foto: Autoria de teste (CC BY)',
          'url': 'https://www.inaturalist.org/observations/$id',
          'observed_on': '2026-10-15',
          'distance_m': 340,
          'approximate_location': true,
        },
      ],
      'fetched_at': '2026-11-15T12:00:00Z',
      'limited': false,
    });

class FaunaFake implements FaunaSource {
  final nearbyRequests = <int>[];
  final nearbyResponses = <Completer<FaunaResult>>[];
  final mapResponses = <Completer<FaunaResult>>[];
  @override
  Future<FaunaResult> nearby(double latitude, double longitude, int radius) {
    nearbyRequests.add(radius);
    final pending = Completer<FaunaResult>();
    nearbyResponses.add(pending);
    return pending.future;
  }

  @override
  Future<FaunaResult> bounds(LatLngBounds bounds) {
    final pending = Completer<FaunaResult>();
    mapResponses.add(pending);
    return pending.future;
  }
}

void main() {
  testWidgets(
    'radius changes ignore stale responses and show optional outage/retry',
    (tester) async {
      final source = FaunaFake();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FaunaNearby(
                latitude: -29.79,
                longitude: -51.15,
                source: source,
              ),
            ),
          ),
        ),
      );
      expect(source.nearbyRequests, [1000]);
      await tester.tap(find.text('5 km'));
      await tester.pump();
      source.nearbyResponses[1].complete(faunaResult(2));
      await tester.pumpAndSettle();
      source.nearbyResponses[0].complete(faunaResult(1));
      await tester.pumpAndSettle();
      expect(find.text('Tapicuru 2'), findsOneWidget);
      expect(find.text('Tapicuru 1'), findsNothing);
      await tester.tap(find.text('500 m'));
      await tester.pump();
      source.nearbyResponses[2].completeError(Exception('offline'));
      await tester.pumpAndSettle();
      expect(find.text('Tentar novamente'), findsOneWidget);
      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();
      source.nearbyResponses[3].complete(
        FaunaResult.fromJson({'observations': []}),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Isso não significa ausência de fauna'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [390.0, 1280.0]) {
    testWidgets('fauna credit, details and radius fit $width', (tester) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final source = FaunaFake();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FaunaNearby(
                  latitude: -29.79,
                  longitude: -51.15,
                  source: source,
                ),
              ),
            ),
          ),
        ),
      );
      source.nearbyResponses[0].complete(faunaResult(1));
      await tester.pumpAndSettle();
      expect(find.text('Foto: Autoria de teste (CC BY)'), findsOneWidget);
      await tester.tap(find.text('Tapicuru 1'));
      await tester.pumpAndSettle();
      expect(find.text('Ver no iNaturalist'), findsOneWidget);
      expect(
        find.textContaining('O marcador não indica o ponto exato.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();
    });
  }

  testWidgets(
    'map layer starts disabled, avoids wide queries and discards disabled response',
    (tester) async {
      final source = FaunaFake();
      final controller = FaunaMapController(source: source);
      addTearDown(controller.dispose);
      final bounds = LatLngBounds(
        const LatLng(-30, -52),
        const LatLng(-29, -51),
      );
      expect(controller.enabled, isFalse);
      controller.updateViewport(9, bounds);
      await tester.pump(const Duration(seconds: 1));
      expect(source.mapResponses, isEmpty);
      controller.toggle(true, 3, bounds);
      expect(controller.message, contains('Aproxime'));
      expect(source.mapResponses, isEmpty);
      controller.toggle(true, 10, bounds);
      await tester.pump(const Duration(milliseconds: 1));
      expect(source.mapResponses.length, 1);
      controller.toggle(false, 10, bounds);
      source.mapResponses[0].complete(faunaResult(1));
      await tester.pump();
      expect(controller.observations, isEmpty);
      expect(controller.loading, isFalse);
      controller.toggle(true, 10, bounds);
      await tester.pump(const Duration(milliseconds: 1));
      source.mapResponses[1].complete(faunaResult(2));
      await tester.pump();
      expect(controller.observations.single.id, 2);
    },
  );
  testWidgets('map debounce, stale viewport, span guard and limit',
      (tester) async {
    final source = FaunaFake();
    final controller = FaunaMapController(source: source);
    addTearDown(controller.dispose);
    final area = LatLngBounds(const LatLng(-30, -52), const LatLng(-29, -51));
    controller.toggle(true, 8, area);
    await tester.pump(const Duration(milliseconds: 1));
    controller.updateViewport(9, area);
    await tester.pump(const Duration(milliseconds: 699));
    expect(source.mapResponses.length, 1);
    source.mapResponses[0].complete(faunaResult(1));
    await tester.pump();
    expect(controller.observations, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(source.mapResponses.length, 2);
    final item = {
      'id': 2,
      'scientific_name': 'Test species',
      'latitude': -29.8,
      'longitude': -51.1,
    };
    source.mapResponses[1].complete(
        FaunaResult.fromJson({'observations': List.filled(120, item)}));
    await tester.pump();
    expect(controller.observations.length, 100);
    controller.updateViewport(
        9, LatLngBounds(const LatLng(-34, -52), const LatLng(-29, -51)));
    await tester.pump(const Duration(seconds: 1));
    expect(source.mapResponses.length, 2);
    expect(controller.message, contains('Aproxime'));
    controller.toggle(true, 9, area);
    await tester.pump(const Duration(milliseconds: 1));
    source.mapResponses.last.completeError(Exception('offline'));
    await tester.pump();
    expect(controller.message, contains('temporariamente indisponível'));
  });
}
