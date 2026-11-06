import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/models/clue_observation.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';

void main() {
  test('age only calculated for explicit timezone and unknown metrics stay raw',
      () {
    final now = DateTime.utc(2026, 10, 27);
    expect(observationTime('2026-10-25T00:00:00Z', now: now),
        contains('há 2 dias'));
    expect(observationTime('2026-10-25 00:00:00', now: now),
        contains('fuso não informado'));
    expect(
        observationTime('2026-10-28T00:00:00Z', now: now), contains('futura'));
    final reading =
        ClueReading.fromJson({'payload_raw': '{"status":"ok","foo":12}'});
    expect(reading.measurements, isEmpty);
    expect(reading.raw, contains('foo'));
  });
  test('snapshot preserves zero and checks analyzed coordinates', () {
    final snapshot = EnvironmentalSnapshot({
      'status': 'completed',
      'analyzed_latitude': -29.0,
      'analyzed_longitude': -51.0,
      'vegetation_percent': 0,
    });
    expect(snapshot.data['vegetation_percent'], 0);
    expect(snapshot.data['altitude_m'], isNull);
    expect(snapshot.matches(-29, -51), isTrue);
    expect(snapshot.matches(-28, -51), isFalse);
    expect(EnvironmentalSnapshot.indicators.length, 8);
  });
  test('unknown reading and legacy units remain uninterpreted', () {
    expect(ClueReading.fromJson({'payload_raw': '<xml>'}).payload, isNull);
    final reading = ClueReading.fromJson({'payload_raw': '{"Temperatura":22}'});
    expect(reading.measurements, {'Temperatura': 22});
    expect(reading.unit('Temperatura'), 'unidade não informada');
    expect(reading.simulated, isFalse);
  });
  test('declared simulation and measurement attributes are separated', () {
    final reading = ClueReading.fromJson({
      'payload_raw': '{"Temperatura":0,"unidades":{"Temperatura":"°C"},'
          '"dados_ficticios":true,"id_dispositivo":"virtual",'
          '"instante_medicao":"2026-10-26T10:00:00-03:00"}'
    });
    expect(reading.measurements, {'Temperatura': 0});
    expect(reading.unit('Temperatura'), '°C');
    expect(reading.simulated, isTrue);
    expect(reading.measuredAt, endsWith('-03:00'));
  });
  test('observations are read-only and unrelated metadata survives', () {
    final clue = LivingClueModel.fromJson({
      'id': 8,
      'category_id': 1,
      'metadata': {
        'custom': [1, 2]
      },
      'environmental_context': {'status': 'pending'},
      'sensor_readings': [
        {'id': 9, 'living_clue_id': 8, 'payload_raw': '[]'}
      ]
    });
    expect(clue.environmentalContext!.status, 'pending');
    expect(clue.sensorReadings.single.id, 9);
    expect(clue.toJson().containsKey('sensor_readings'), isFalse);
    expect(clue.toJson()['metadata'], {
      'custom': [1, 2]
    });
  });
}
