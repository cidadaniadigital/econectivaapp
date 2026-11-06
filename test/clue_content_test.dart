import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/widgets/clue_content.dart';
void main() {
  test('content links only use explicit HTTP references and deduplicate', () {
    final clue = LivingClueModel(id:8, name:'Texto', categoryId:1,
      description:'Texto e vídeo https://example.test/video.',
      metadata:{'source_url':'https://example.test/video', 'url':'javascript:alert(1)'});
    expect(ClueContent.links(clue).map((uri) => uri.toString()), ['https://example.test/video']);
  });
}
