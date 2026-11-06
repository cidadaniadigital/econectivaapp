import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/widgets/discovery_content.dart';

LivingClueModel clue(int id,
        {Map<String, dynamic>? metadata,
        String? image = 'https://example.test/cover.jpg'}) =>
    LivingClueModel(
        id: id,
        name: 'Pista $id',
        categoryId: 12,
        imageUrl: image,
        metadata: metadata);
void main() {
  test('random selection ignores editorial ranks without mutating catalogue',
      () {
    final items = [
      clue(59),
      clue(71, metadata: {'destaque_inicio_ordem': 3}),
      clue(72, metadata: {'destaque_inicio_ordem': 1}),
      clue(73, metadata: {'destaque_inicio_ordem': 2})
    ];
    final expected = [...items]..shuffle(Random(42));
    expect(
        DiscoveryContent.heroItems(items, random: Random(42)).map((e) => e.id),
        expected.take(3).map((e) => e.id));
    expect(items.map((e) => e.id), [59, 71, 72, 73]);
  });
  test('all image clues are eligible regardless of old hiding metadata', () {
    final items = [
      clue(59, metadata: {'ocultar_capa_inicio': true}),
      clue(70, image: null, metadata: {'destaque_inicio_ordem': 1}),
      clue(71),
      clue(72)
    ];
    expect(DiscoveryContent.heroItems(items).map((e) => e.id),
        unorderedEquals([59, 71, 72]));
  });
  test('selection stays stable during rebuilds and uses three distinct clues',
      () {
    final items = [clue(4), clue(3), clue(2), clue(1)];
    final first = DiscoveryContent.heroItems(items).map((e) => e.id).toList();
    expect(first, hasLength(3));
    expect(first.toSet(), hasLength(3));
    expect(DiscoveryContent.heroItems(items).map((e) => e.id), first);
    final selections = List.generate(
        10,
        (seed) => DiscoveryContent.heroItems(items, random: Random(seed))
            .map((e) => e.id)
            .join(','));
    expect(selections.toSet().length, greaterThan(1));
  });
}
