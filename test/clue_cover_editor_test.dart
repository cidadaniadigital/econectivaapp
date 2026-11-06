import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/widgets/clue_cover_editor.dart';

void main() {
  test('removing association preserves other metadata and document', () async {
    final clue = LivingClueModel(
        id: 8,
        name: 'Exemplo',
        categoryId: 1,
        descriptionDelta: '{"ops":[]}',
        imageUrl: 'https://example.test/image.jpg',
        metadata: {
          'imagem_capa_arquivo_id': 15,
          'typed': {'value': 3}
        });
    final selection = CoverSelection();
    selection.remove();
    await selection.apply(clue);
    expect(clue.metadata, {
      'capa_automatica_desativada': true,
      'typed': {'value': 3}
    });
    expect(clue.imageUrl, isNull);
    expect(clue.descriptionDelta, '{"ops":[]}');
    selection.dispose();
  });
}
