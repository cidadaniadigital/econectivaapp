import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/utils/quill_document_utils.dart';

void main() {
  test('loads a stored Quill delta', () {
    final document = QuillDocumentUtils.fromStored(
      delta: '[{"insert":"Título"},{"insert":"\\n","attributes":{"header":1}}]',
      plainText: 'fallback',
    );

    expect(document.toPlainText().trim(), 'Título');
    expect(document.toDelta().toJson().last['attributes'], {'header': 1});
  });

  test('falls back to plain text when delta is invalid', () {
    final document = QuillDocumentUtils.fromStored(
      delta: 'invalid json',
      plainText: 'Descrição antiga',
    );

    expect(document.toPlainText().trim(), 'Descrição antiga');
  });

  test('stores plain text and delta from the same document', () {
    final controller = QuillController.basic();
    controller.document.insert(0, 'Conteúdo');

    expect(QuillDocumentUtils.plainText(controller), 'Conteúdo');
    expect(QuillDocumentUtils.encodeDelta(controller), contains('Conteúdo'));

    controller.dispose();
  });

  test('does not store an empty document delta', () {
    final controller = QuillController.basic();

    expect(QuillDocumentUtils.plainText(controller), isEmpty);
    expect(QuillDocumentUtils.encodeDelta(controller), isNull);

    controller.dispose();
  });
}
