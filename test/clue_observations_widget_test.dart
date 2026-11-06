import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/widgets/clue_observations.dart';

void main() {
  testWidgets('missing location and unknown payload remain usable', (tester) async {
    final clue = LivingClueModel.fromJson({'id': 8, 'category_id': 1,
      'sensor_readings': [{'id': 1, 'living_clue_id': 8, 'payload_raw': 'legacy'}]});
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: ClueObservations(clue: clue)))));
    expect(find.text('Sem localização informada.'), findsOneWidget);
    expect(find.text('Formato sem interpretação disponível'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('all eight indicators show without overflowing at 320px', (tester) async {
    tester.view.physicalSize = const Size(320, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final clue = LivingClueModel.fromJson({'id': 8, 'category_id': 1,
      'latitude': -29, 'longitude': -51, 'environmental_context': {
        'status': 'completed', 'analyzed_latitude': -29,
        'analyzed_longitude': -51, 'vegetation_percent': 0,
        'sources': {'land_cover': {'dataset': 'Fonte armazenada', 'version': 'v1'}}
      }});
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: ClueObservations(clue: clue)))));
    expect(find.text('Densidade populacional'), findsOneWidget);
    expect(find.text('0,00 %'), findsOneWidget);
    expect(find.text('Fonte armazenada • v1'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
