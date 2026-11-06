import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/webclients/category_webclient.dart';
import 'package:unisinos_usp_app/webclients/file_webclient.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';
import 'package:unisinos_usp_app/webclients/preferences_webclient.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:unisinos_usp_app/widgets/clue_cover.dart';
import 'usp_plan_test.dart' show capture;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'real Android document picker uploads, replaces and removes cover and attachment',
      (tester) async {
    expect(Uri.parse(WebClient.apiBaseUrl).host, '127.0.0.1');
    await (await SharedPreferences.getInstance()).clear();
    await app.main();
    await tester.pump();
    final auth = await UserWebclient().login(
        mail: const String.fromEnvironment('E2E_EMAIL'),
        password: const String.fromEnvironment('E2E_PASSWORD'));
    await Get.find<UserController>().savePrefs(auth);
    await PreferencesWebclient().setEditingEnabled(true);
    final category = (await CategoryWebclient().fetch())
        .firstWhere((c) => c.name == 'Laboratório de integrações');
    final client = LivingClueWebclient();
    final files = FileWebclient();
    final clue = await client.create(LivingClueModel(
        id: 0,
        name:
            'USP arquivos sintéticos ${DateTime.now().microsecondsSinceEpoch}',
        categoryId: category.id,
        metadata: {
          'typed': {'number': 0}
        }));
    Future<void> edit() async {
      await tester.tap(find.byTooltip('Editar pista'));
      await tester.pumpAndSettle();
    }

    Future<void> choose() async {
      await tester.ensureVisible(find.text('Escolher imagem'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Escolher imagem'));
      await tester.pump();
      for (var attempt = 0;
          attempt < 180 && find.text('Substituir imagem').evaluate().isEmpty;
          attempt++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.text('Substituir imagem'), findsOneWidget);
    }

    Future<void> save() async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Salvar').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar').last);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    try {
      Get.offAllNamed('/living_clues/show', parameters: {'id': '${clue.id}'});
      await tester.pumpAndSettle();
      await edit();
      await choose();
      await save();
      final first =
          (await client.fetchById(clue.id)).metadata!['imagem_capa_arquivo_id'];
      expect(first, isNotNull);
      final coverPixels = find.descendant(
          of: find.byType(ClueCover), matching: find.byType(RawImage));
      for (var attempt = 0;
          attempt < 20 &&
              tester
                  .widgetList<RawImage>(coverPixels)
                  .every((image) => image.image == null);
          attempt++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(
          tester
              .widgetList<RawImage>(coverPixels)
              .any((image) => image.image != null),
          isTrue,
          reason: 'The uploaded cover must render pixels on Android.');
      await capture(tester, 'native-cover-uploaded');
      await edit();
      await choose();
      await save();
      final second =
          (await client.fetchById(clue.id)).metadata!['imagem_capa_arquivo_id'];
      expect(second, isNot(first));
      expect((await files.fetch(livingClueId: clue.id)).length, 2);
      await edit();
      await tester.ensureVisible(find.text('Remover capa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover capa'));
      await save();
      final removed = await client.fetchById(clue.id);
      expect(removed.metadata, {
        'typed': {'number': 0}
      });
      expect((await files.fetch(livingClueId: clue.id)).length, 2);
      await tester.ensureVisible(find.text('Adicionar anexo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adicionar anexo'));
      await tester.pump();
      for (var attempt = 0;
          attempt < 180 && find.text('usp-plan-note.txt').evaluate().isEmpty;
          attempt++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.text('usp-plan-note.txt'), findsOneWidget);
      await capture(tester, 'native-attachment-uploaded');
      final row = find.ancestor(
          of: find.text('usp-plan-note.txt'), matching: find.byType(ListTile));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(
          find.descendant(of: row, matching: find.byTooltip('Excluir anexo')));
      await tester.pumpAndSettle();
      expect(find.text('Excluir anexo?'), findsOneWidget);
      await tester.tap(find.text('Excluir').last);
      await tester.pumpAndSettle();
      expect(
          (await files.fetch(livingClueId: clue.id))
              .any((file) => file.name == 'usp-plan-note.txt'),
          isFalse);
    } finally {
      for (final file in await files.fetch(livingClueId: clue.id)) {
        await files.delete(file.id);
      }
      await client.delete(clue.id);
    }
  }, timeout: const Timeout(Duration(minutes: 6)));
}
