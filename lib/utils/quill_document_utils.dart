import 'dart:convert';
import 'package:dart_quill_delta/dart_quill_delta.dart';

import 'package:flutter_quill/flutter_quill.dart';

class QuillDocumentUtils {
  static Document fromStored({String? delta, String? plainText}) {
    if (delta != null && delta.trim().isNotEmpty) {
      try {
        final stored = jsonDecode(delta);
        final decoded = stored is Map ? stored['ops'] : stored;
        if (decoded is List) {
          // fromJson adds a line after the last video on each reopen in Quill 11.5.
          // Our saved Delta already contains the required block boundaries.
          return Document.fromDelta(Delta.fromJson(decoded));
        }
      } catch (_) {
        // Conteúdo legado ou inválido usa a descrição em texto como fallback.
      }
    }

    final document = Document();
    final text = plainText?.trim() ?? '';
    if (text.isNotEmpty) {
      document.insert(0, text);
    }
    return document;
  }

  static String plainText(QuillController controller) {
    return controller.document.toPlainText().replaceAll('\uFFFC', '').trim();
  }

  static String? encodeDelta(QuillController controller) {
    if (plainText(controller).isEmpty &&
        !controller.document
            .toDelta()
            .toJson()
            .any((op) => op['insert'] is Map)) return null;
    return jsonEncode(controller.document.toDelta().toJson());
  }
}
