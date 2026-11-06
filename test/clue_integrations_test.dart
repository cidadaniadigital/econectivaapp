import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:unisinos_usp_app/models/clue_integration.dart';
import 'package:unisinos_usp_app/utils/quill_document_utils.dart';
import 'package:unisinos_usp_app/widgets/clue_media.dart';
import 'package:unisinos_usp_app/widgets/living_clue_description_view.dart';

void main() {
  test(
    'provider URLs reject lookalikes, markup, credentials and active schemes',
    () {
      expect(
        ClueIntegration.validateURL(
          'genially',
          'https://view.genially.com/60e5417ee87d780d572d8c48/interactive-content',
        ),
        isNull,
      );
      expect(
        ClueIntegration.validateURL(
          'padlet',
          'https://padlet.com/embed/abcdefghijklmnop',
        ),
        isNull,
      );
      expect(
        ClueIntegration.validateURL(
          'framevr',
          'https://framevr.io/example-room',
        ),
        isNull,
      );
      expect(
        ClueIntegration.validateURL('overte', 'hifi://world.example.org'),
        isNotNull,
      );
      for (final url in [
        'javascript:alert(1)',
        'https://view.genially.com.evil.test/60e5417ee87d780d572d8c48',
        'https://user:password@view.genially.com/60e5417ee87d780d572d8c48',
        '<iframe src="https://view.genially.com/60e5417ee87d780d572d8c48">',
      ]) {
        expect(ClueIntegration.validateURL('genially', url), isNotNull);
      }
      expect(
        ClueIntegration.validateURL('framevr', 'https://framevr.io:444/room'),
        isNotNull,
      );
    },
  );

  test(
    'retired world clients are unavailable without discarding stored content',
    () {
      for (final provider in ['overte', 'vircadia']) {
        final legacy = ClueIntegration(
          provider: provider,
          url: 'hifi://world.example.org',
        );
        expect(ClueIntegration.providers, isNot(contains(provider)));
        expect(legacy.supported, isFalse);
        expect(legacy.embedURI, isNull);
        expect(ClueIntegration.validateURL(provider, legacy.url), isNotNull);
        expect(
          ClueIntegration.decode(legacy.encode())!.toJson(),
          legacy.toJson(),
        );
      }
    },
  );
  test(
    'mixed blocks roundtrip in order including unknown embeds and versions',
    () {
      final ops = <Map<String, dynamic>>[
        {'insert': 'Antes\n'},
      ];
      for (final provider in ClueIntegration.providers) {
        ops.add({
          'insert': {
            'onlife': ClueIntegration(
              provider: provider,
              url: 'https://example.org/reference',
              title: 'Título $provider',
            ).encode(),
          },
        });
        ops.add({'insert': '\n'});
      }
      ops.addAll([
        {
          'insert': {'video': 'https://youtu.be/dQw4w9WgXcQ'},
        },
        {'insert': '\n'},
        {
          'insert': {
            'future-provider': {'v': 2, 'opaque': 'do not discard'},
          },
        },
        {'insert': '\nDepois\n'},
      ]);
      final c = QuillController(
        document: QuillDocumentUtils.fromStored(delta: jsonEncode(ops)),
        selection: const TextSelection.collapsed(offset: 0),
      );
      final encoded = QuillDocumentUtils.encodeDelta(c)!;
      expect(jsonDecode(encoded), ops);
      expect(QuillDocumentUtils.plainText(c), 'Antes\n\n\n\n\n\nDepois');
      final reopened = QuillDocumentUtils.fromStored(delta: encoded);
      expect(reopened.toDelta().toJson(), ops);
      c.dispose();
    },
  );

  test('integration insertion and removal keep surrounding author text', () {
    final c = QuillController(
      document: Document.fromJson([
        {'insert': 'abc\ndef\n'},
      ]),
      selection: const TextSelection.collapsed(offset: 4),
    );
    const block = ClueIntegration(
      provider: 'padlet',
      url: 'https://padlet.com/embed/abcdefghijklmnop',
    );
    c.replaceText(
      4,
      0,
      BlockEmbed('onlife', block.encode()),
      const TextSelection.collapsed(offset: 5),
    );
    final raw = QuillDocumentUtils.encodeDelta(c)!;
    expect(raw, contains('onlife'));
    expect(
      QuillDocumentUtils.fromStored(delta: raw).toDelta().toJson(),
      c.document.toDelta().toJson(),
    );
    c.replaceText(4, 1, '', const TextSelection.collapsed(offset: 4));
    expect(c.document.toPlainText(), 'abc\ndef\n');
    c.dispose();
  });

  test('integration suppresses duplicate preview of its source URL', () {
    const block = ClueIntegration(
      provider: 'padlet',
      url: 'https://padlet.com/embed/abcdefghijklmnop',
    );
    final c = QuillController(
      document: Document.fromJson([
        {
          'insert': {'onlife': block.encode()},
        },
        {'insert': '\n${block.url}\n'},
      ]),
      selection: const TextSelection.collapsed(offset: 0),
    );
    expect(documentLinks(c), isEmpty);
    c.dispose();
  });

  testWidgets(
    'native reader offers a provider fallback and preserves unknown content',
    (tester) async {
      final delta = jsonEncode([
        {'insert': 'Descrição mantida\n'},
        {
          'insert': {
            'onlife': const ClueIntegration(
              provider: 'padlet',
              url: 'https://padlet.com/embed/abcdefghijklmnop',
            ).encode(),
          },
        },
        {'insert': '\n'},
        {
          'insert': {
            'future-provider': {'v': 2, 'reference': 'opaque'},
          },
        },
        {
          'insert': {'image': 'https://example.com/image.png'},
        },
        {'insert': '\n'},
        {'insert': '\nFinal da pista\n'},
      ]);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            FlutterQuillLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('pt', 'BR')],
          home: Scaffold(
            body: SingleChildScrollView(
              child: LivingClueDescriptionView(plainText: '', delta: delta),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Abrir no navegador'), findsOneWidget);
      expect(
        find.textContaining('Conteúdo de outra versão preservado'),
        findsNWidgets(2),
      );
      expect(find.byType(Image), findsNothing);
      expect(find.text('Abrir na origem'), findsOneWidget);
      expect(
        find.textContaining('Final da pista', findRichText: true),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
