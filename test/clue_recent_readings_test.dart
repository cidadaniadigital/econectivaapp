import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/models/clue_observation.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/widgets/clue_recent_readings.dart';

ClueReading reading(int id,
        {int clueId = 8, num temperature = 0, bool simulated = false}) =>
    ClueReading.fromJson({
      'id': id,
      'living_clue_id': clueId,
      'created_at': '2026-10-29T10:12:30-03:00',
      'payload_raw': jsonEncode({
        'Temperatura': temperature,
        'CO2': 650,
        'unidades': {'Temperatura': '°C', 'CO2': 'ppm'},
        'dados_ficticios': simulated,
        'id_dispositivo': 'sensor-1',
        'origem': 'MQTT'
      })
    });
LivingClueModel clue(List<ClueReading> readings, {int id = 8}) =>
    LivingClueModel(id: id, name: 'Sensor', categoryId: 1)
      ..sensorReadings = readings;
Widget view(LivingClueModel model,
        {Future<List<ClueReading>> Function(int)? loader}) =>
    MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: ClueRecentReadings(clue: model, loadReadings: loader))));

void main() {
  test('compact timestamps preserve declared offset and do not infer a zone',
      () {
    expect(readingReceivedLabel('2026-10-29T10:12:30-03:00'),
        '29/10/2026 às 10:12:30 · UTC-03:00');
    expect(readingReceivedLabel('2026-10-29T13:12:30Z'), contains('UTC'));
    expect(readingReceivedLabel('2026-10-29 10:12:30'),
        contains('fuso não informado'));
  });

  testWidgets(
      'latest values stand out, unrelated clues are excluded, history is bounded',
      (tester) async {
    await tester.pumpWidget(view(clue([
      ...List.generate(12, (i) => reading(i + 1, temperature: i)),
      reading(99, clueId: 9, temperature: 999),
      reading(13, simulated: true),
    ])));
    await tester.pumpAndSettle();
    expect(find.text('ÚLTIMA LEITURA RECEBIDA'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('°C'), findsOneWidget);
    expect(find.text('650'), findsOneWidget);
    expect(find.text('ppm'), findsOneWidget);
    expect(find.text('999'), findsNothing);
    expect(find.text('DADOS FICTÍCIOS · Demonstração'), findsOneWidget);
    expect(find.text('Leituras anteriores (9)'), findsOneWidget);
    await tester.ensureVisible(find.text('Leituras anteriores (9)'));
    await tester.tap(find.text('Leituras anteriores (9)'));
    await tester.pumpAndSettle();
    expect(find.text('Registro #12'), findsOneWidget);
    expect(find.text('Registro #1'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      '320px layout, history, raw details and missing units remain usable',
      (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final legacy = ClueReading.fromJson({
      'id': 2,
      'living_clue_id': 8,
      'payload_raw': '{"Temperatura":22.5,"desconhecido":"preservado"}'
    });
    await tester.pumpWidget(view(clue([legacy, reading(1)])));
    await tester.pumpAndSettle();
    expect(find.text('22,5'), findsOneWidget);
    expect(find.text('unidade não informada'), findsOneWidget);
    await tester.ensureVisible(find.text('Ver dados completos'));
    await tester.tap(find.text('Ver dados completos'));
    await tester.pumpAndSettle();
    expect(find.textContaining('"desconhecido": "preservado"'), findsOneWidget);
    await tester.tap(find.text('Ver dados completos'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Leituras anteriores (1)'));
    await tester.tap(find.text('Leituras anteriores (1)'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Registro #1'));
    await tester.tap(find.text('Registro #1'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'refresh replaces data and a later failure preserves the snapshot',
      (tester) async {
    var fail = false;
    await tester.pumpWidget(
        view(clue([reading(1, temperature: 10)]), loader: (id) async {
      expect(id, 8);
      if (fail) throw StateError('offline');
      return [reading(2, temperature: 20)];
    }));
    await tester.tap(find.text('Atualizar leituras'));
    await tester.pumpAndSettle();
    expect(find.text('20'), findsOneWidget);
    fail = true;
    await tester.tap(find.text('Atualizar leituras'));
    await tester.pumpAndSettle();
    expect(find.text('20'), findsOneWidget);
    expect(find.textContaining('já carregadas foram mantidas'), findsOneWidget);
  });

  testWidgets('a delayed response cannot replace a different clue',
      (tester) async {
    final pending = Completer<List<ClueReading>>();
    await tester
        .pumpWidget(view(clue([reading(1)]), loader: (_) => pending.future));
    await tester.tap(find.text('Atualizar leituras'));
    await tester.pump();
    await tester.pumpWidget(
        view(clue([reading(2, clueId: 9, temperature: 33)], id: 9)));
    pending.complete([reading(3, temperature: 88)]);
    await tester.pumpAndSettle();
    expect(find.text('33'), findsOneWidget);
    expect(find.text('88'), findsNothing);
  });
}
