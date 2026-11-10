import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/services/collection_service.dart';

void main() {
  test(
      'editorial order retains only real members, deduplicates and appends new items',
      () {
    final collection =
        LivingClueModel(id: 8, name: 'Coleção', categoryId: 1, metadata: {
      CollectionService.orderKey: [3, 3, '2', 999, 'invalid']
    });
    expect(
        CollectionService.orderedIds(collection, [1, 2, 3, 4]), [3, 2, 1, 4]);
    expect(CollectionService.orderedIds(collection, []), isEmpty);
    expect(collection.metadata![CollectionService.orderKey],
        [3, 3, '2', 999, 'invalid']);
  });
  test('missing or malformed editorial order yields stable ID order', () {
    final collection = LivingClueModel(id: 8, name: 'Coleção', categoryId: 1);
    expect(CollectionService.orderedIds(collection, [4, 2, 4]), [2, 4]);
    collection.metadata = {CollectionService.orderKey: 'not a list'};
    expect(CollectionService.orderedIds(collection, [4, 2]), [2, 4]);
  });
  test('episode titles stay specific to each CDIG series', () {
    final video =
        LivingClueModel(id: 1, name: 'Video title', categoryId: 1, metadata: {
      'cdig': {'type': 'video', 'id': '9', 'source': 'same'}
    });
    LivingClueModel series(String title) =>
        LivingClueModel(id: 2, name: 'Series', categoryId: 1, metadata: {
          'cdig': {
            'source': 'same',
            'episodes': [
              {
                'ID': '9',
                'Episode': {'Title': title, 'Description': 'Series description'}
              }
            ]
          }
        });
    expect(CollectionService.itemTitle(series('First title'), video),
        'First title');
    expect(CollectionService.itemTitle(series('Second title'), video),
        'Second title');
    expect(CollectionService.itemSubtitle(series('First title'), video),
        'Series description');
    expect(video.name, 'Video title');
    expect(CollectionService.itemTitle(series(''), video), 'Video title');
  });
}
