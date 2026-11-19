import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/webclients/deter_webclient.dart';
import 'package:unisinos_usp_app/widgets/deter_nearby.dart';

Map<String, dynamic> notices(
        {int total = 2, bool covered = true, bool stale = false}) =>
    {
      'covered': covered,
      'total': total,
      'classes': total == 0
          ? []
          : [
              {'class_name': 'DESMATAMENTO_CR', 'count': total}
            ],
      'period_start': '2025-11-19',
      'period_end': '2026-11-19',
      'fetched_at': '2026-11-19T12:00:00Z',
      'stale': stale,
    };

class PendingDeter implements DeterSource {
  final requests = <(double, double, int)>[];
  final pending = <Completer<Map<String, dynamic>>>[];
  @override
  Future<Map<String, dynamic>> nearby(
      double latitude, double longitude, int radius) {
    requests.add((latitude, longitude, radius));
    final response = Completer<Map<String, dynamic>>();
    pending.add(response);
    return response.future;
  }
}

Widget scene(DeterSource source,
        {double latitude = -1.6, double longitude = -55.16}) =>
    MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
            body: SingleChildScrollView(
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: DeterNearby(
                        latitude: latitude,
                        longitude: longitude,
                        source: source)))));
void main() {
  for (final width in [320.0, 390.0, 1280.0]) {
    testWidgets(
        'DETER real contract layout, period and stale message at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final source = PendingDeter();
      await tester.pumpWidget(scene(source));
      expect(source.requests.single.$3, 1000);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      source.pending.single.complete(notices(stale: true));
      await tester.pumpAndSettle();
      expect(find.textContaining('2 avisos no entorno'), findsOneWidget);
      expect(find.text('DESMATAMENTO CR: 2'), findsOneWidget);
      expect(find.textContaining('19/11/2025 a 19/11/2026'), findsOneWidget);
      expect(find.textContaining('Atualização pendente'), findsOneWidget);
      expect(find.textContaining('não equivalem à taxa anual'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('rapid radius changes ignore older success and failure',
      (tester) async {
    final source = PendingDeter();
    await tester.pumpWidget(scene(source));
    await tester.tap(find.text('5 km'));
    await tester.pump();
    await tester.tap(find.text('500 m'));
    await tester.pump();
    expect(source.requests.map((r) => r.$3).toList(), [1000, 5000, 500]);
    source.pending[2].complete(notices(total: 3));
    await tester.pumpAndSettle();
    source.pending[0].complete(notices(total: 7));
    source.pending[1].completeError(Exception('old failure'));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 avisos no entorno'), findsOneWidget);
    expect(find.textContaining('7 avisos no entorno'), findsNothing);
    expect(find.text('Tentar novamente'), findsNothing);
  });
  testWidgets(
      'coordinate changes invalidate pending requests and disposal is safe',
      (tester) async {
    final source = PendingDeter();
    await tester.pumpWidget(scene(source));
    await tester.pumpWidget(scene(source, latitude: -30, longitude: -51));
    expect(source.requests.last, (-30.0, -51.0, 1000));
    source.pending[1].complete(notices(covered: false));
    await tester.pumpAndSettle();
    source.pending[0].complete(notices());
    await tester.pumpAndSettle();
    expect(find.textContaining('fora da cobertura'), findsOneWidget);
    expect(find.textContaining('2 avisos no entorno'), findsNothing);
    await tester.tap(find.text('5 km'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    source.pending.last.complete(notices());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('failed query can be retried and empty coverage is explicit',
      (tester) async {
    final source = PendingDeter();
    await tester.pumpWidget(scene(source));
    source.pending.single.completeError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(find.text('Tentar novamente'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();
    source.pending.last.complete(notices(total: 0));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nenhum aviso encontrado'), findsOneWidget);
    expect(find.textContaining('Isso não comprova ausência'), findsOneWidget);
    expect(find.textContaining('fora da cobertura'), findsNothing);
  });
}
