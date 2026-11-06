import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/widgets/clue_description_editor.dart';
import 'package:unisinos_usp_app/widgets/living_clue_description_editor.dart';

void main() {
  testWidgets('edits text preserving formatted text and linked embedded blocks',
      (tester) async {
    final ops = [
      {
        'insert': 'Antes',
        'attributes': {'bold': true}
      },
      {
        'insert': {
          'onlife': {'type': 'agent', 'id': 5}
        }
      },
      {'insert': '\n'}
    ];
    String? updated;
    await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [FlutterQuillLocalizations.delegate],
        home: Scaffold(
            body: SingleChildScrollView(
                child: ClueDescriptionEditor(
                    delta: jsonEncode(ops),
                    onChanged: (value) => updated = value)))));
    final editor = tester.widget<LivingClueDescriptionEditor>(
        find.byType(LivingClueDescriptionEditor));
    editor.controller
        .replaceText(0, 5, 'Depois', const TextSelection.collapsed(offset: 6));
    await tester.pump();
    final decoded = jsonDecode(updated!) as List<dynamic>;
    expect(decoded[0], {
      'insert': 'Depois',
      'attributes': {'bold': true}
    });
    expect(decoded[1], ops[1]);
    expect(decoded.last, ops.last);
    expect(tester.takeException(), isNull);
  });
}
