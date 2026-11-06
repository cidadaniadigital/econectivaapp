import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';

void main() {
  test('accepts an empty API collection represented as null', () {
    expect(LivingClueModel.fromJsonArray('null'), isEmpty);
  });
  Map<String, dynamic> fixture() => {
        'id': 7,
        'name': 'Pista sem localização',
        'category_id': 2,
        'latitude': null,
        'longitude': null,
        'description': 'Texto',
        'description_delta': '[{"insert":"Texto\\n"}]',
        'metadata': {
          'classificacao': {
            'tags': ['A', 'B']
          },
          'valor': 42
        },
        'is_active': true
      };

  test('reads current API clues without legacy biome and optional coordinates',
      () {
    final model = LivingClueModel.fromJson(fixture());
    expect(model.biomeId, isNull);
    expect(model.latitude, isNull);
    expect(model.longitude, isNull);
    expect(model.hasLocation, isFalse);
  });
  test('keeps zero coordinates valid and rejects invalid map locations', () {
    final data = fixture()..addAll({'latitude': 0, 'longitude': '0'});
    final model = LivingClueModel.fromJson(data);
    expect(model.hasLocation, isTrue);
    model.latitude = 91;
    expect(model.hasLocation, isFalse);
    model.latitude = double.nan;
    expect(model.hasLocation, isFalse);
  });
  test('round trip preserves nested metadata and document integrations', () {
    final data = fixture();
    data['description_delta'] = jsonEncode([
      {
        'insert': 'Texto',
        'attributes': {'bold': true}
      },
      {
        'insert': {
          'onlife': {'type': 'agent', 'id': 4}
        }
      },
      {'insert': '\n'}
    ]);
    final encoded = LivingClueModel.fromJson(data).toJson();
    expect(encoded['metadata'], data['metadata']);
    expect(encoded['description_delta'], data['description_delta']);
    expect(encoded['description_format_version'], 1);
    expect(encoded.containsKey('biome_id'), isFalse);
    expect(encoded.containsKey('territory_id'), isFalse);
  });
  test('only clears location when explicitly requested', () {
    final model = LivingClueModel.fromJson(fixture());
    expect(model.toJson().containsKey('remove_location'), isFalse);
    model.removeLocation = true;
    expect(model.toJson()['remove_location'], isTrue);
  });
  test('parses list responses and string identifiers', () {
    final data = fixture()..addAll({'id': '12', 'category_id': '3'});
    final models = LivingClueModel.fromJsonArray(jsonEncode([data]));
    expect(models.single.id, 12);
    expect(models.single.categoryId, 3);
  });
}
