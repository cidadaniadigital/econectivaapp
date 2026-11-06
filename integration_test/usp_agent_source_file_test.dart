import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgets_spo/widgets_spo.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/models/chat_template_model.dart';
import 'package:unisinos_usp_app/webclients/chat_template_webclient.dart';
import 'package:unisinos_usp_app/webclients/chat_template_file_webclient.dart';
import 'package:unisinos_usp_app/webclients/file_webclient.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:unisinos_usp_app/webclients/preferences_webclient.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'usp_plan_test.dart' show capture;
import 'evidence_path.dart' show publishEvidence;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'agent sources use real URL extraction and actual document picker multipart',
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
    final templates = ChatTemplateWebclient(),
        sources = ChatTemplateFileWebclient();
    final beforeFiles =
        (await FileWebclient().fetch()).map((f) => f.id).toSet();
    final template = await templates.create(ChatTemplateModel(
        id: 0,
        name:
            'USP fonte arquivo descartável ${DateTime.now().microsecondsSinceEpoch}',
        systemInstruction:
            'Use as fontes disponíveis e reconheça dados ausentes.'));
    Future<void> settle() async =>
        tester.pumpAndSettle(const Duration(milliseconds: 500));
    Future<void> add() async {
      await tester.ensureVisible(find.text('Adicionar'));
      await tester.tap(find.text('Adicionar'));
      await settle();
    }

    Future<void> name(String value) async {
      final field = find.byWidgetPredicate(
          (w) => w is InputText && w.hintText == 'Nome da fonte');
      await tester.ensureVisible(field);
      await tester.enterText(field, value);
    }

    Future<void> url(String value) async {
      final field = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'URL');
      await tester.ensureVisible(field);
      await tester.tap(field);
      await settle();
      await tester.enterText(field, value);
      await settle();
      expect(tester.widget<TextField>(field).controller!.text, value);
    }

    Future<void> save() async {
      FocusManager.instance.primaryFocus?.unfocus();
      await settle();
      await tester.ensureVisible(find.text('Salvar fonte'));
      await tester.tap(find.text('Salvar fonte'));
      await tester.pump();
      for (var attempt = 0;
          attempt < 80 && find.text('Salvando...').evaluate().isNotEmpty;
          attempt++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.text('Salvando...'), findsNothing,
          reason: 'Wait for the actual HTTP operation to complete.');
      await settle();
    }

    try {
      Get.offAllNamed('/chat_templates/update',
          parameters: {'id': '${template.id}'});
      await settle();
      await add();
      await name('URL sintética');
      await url('http://127.0.0.1/');
      await save();
      expect(
          Uri.parse(Get.currentRoute).path, '/chat_templates/sources/create');
      expect(find.textContaining('Não foi possível adicionar a fonte.'),
          findsWidgets);
      expect(await sources.fetch(chatTemplateId: template.id), isEmpty);
      await capture(tester, 'agent-source-url-failure');
      await url('https://example.com');
      await save();
      await capture(tester, 'agent-source-url-retry-state');
      final retrySources = await sources.fetch(chatTemplateId: template.id);
      await publishEvidence('agent-source-url-retry-diagnostic.json', {
        'route': Get.currentRoute,
        'source_count': retrySources.length,
        'statuses': retrySources.map((source) => source.status).toList(),
      });
      expect(Uri.parse(Get.currentRoute).path, '/chat_templates/update');
      final imported =
          (await sources.fetch(chatTemplateId: template.id)).single;
      expect(imported.resolvedType, 'url');
      expect(imported.status, 'processed');
      expect(imported.sourceUrl, 'https://example.com');
      expect(imported.extractedContent?.trim().isNotEmpty, true);
      await capture(tester, 'agent-source-url-imported');
      await add();
      await name('Documento sintético');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await settle();
      await tester.tap(find.text('Arquivo').last);
      await settle();
      await tester.tap(find.text('Selecionar arquivo'));
      await tester.pump();
      for (var i = 0;
          i < 180 && find.text('Arquivo: usp-plan-note.txt').evaluate().isEmpty;
          i++) await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Arquivo: usp-plan-note.txt'), findsOneWidget);
      await capture(tester, 'agent-source-file-selected');
      await save();
      expect(Uri.parse(Get.currentRoute).path, '/chat_templates/update');
      final all = await sources.fetch(chatTemplateId: template.id);
      expect(all, hasLength(2));
      final uploaded = all.singleWhere((f) => f.name == 'Documento sintético');
      expect(uploaded.resolvedType, 'file');
      expect(uploaded.status, 'processed');
      expect(uploaded.originalContent ?? uploaded.content,
          contains('Anexo sintético USP. Sem dados pessoais.'));
      expect(uploaded.sourceUrl ?? uploaded.url ?? '', '');
      expect(
          (await FileWebclient().fetch()).map((f) => f.id).toSet(), beforeFiles,
          reason:
              'Agent source uploads must not create an orphan generic file.');
      Get.offAllNamed('/chat_templates/update',
          parameters: {'id': '${template.id}'});
      await settle();
      await tester.ensureVisible(find.text('Documento sintético'));
      await capture(tester, 'agent-source-file-persisted');
      final row = find
          .ancestor(
              of: find.text('Documento sintético'),
              matching: find.byType(ListTile))
          .first;
      await tester.tap(
          find.descendant(of: row, matching: find.byTooltip('Excluir fonte')));
      await settle();
      expect(
          (await sources.fetch(chatTemplateId: template.id))
              .map((f) => f.id)
              .toList(),
          [imported.id]);
      await publishEvidence('agent-source-file-checks.json', {
        'status': 'aprovado',
        'url_failure_retains_form': true,
        'url_retry_no_duplicate': true,
        'real_url_import': 'https://example.com',
        'actual_android_documentsui': true,
        'multipart_file_processed': true,
        'no_generic_file_created': true,
        'no_temporary_url_persisted': true,
        'file_delete_preserves_url_source': true
      });
    } finally {
      for (final source in await sources.fetch(chatTemplateId: template.id))
        await sources.delete(source.id!);
      await templates.delete(template.id);
    }
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 4)));
}
