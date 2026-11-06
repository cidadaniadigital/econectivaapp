import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgets_spo/widgets_spo.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/models/node_model.dart';
import 'package:unisinos_usp_app/models/chat_template_model.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:unisinos_usp_app/webclients/preferences_webclient.dart';
import 'package:unisinos_usp_app/webclients/node_type_webclient.dart';
import 'package:unisinos_usp_app/webclients/node_webclient.dart';
import 'package:unisinos_usp_app/webclients/node_link_webclient.dart';
import 'package:unisinos_usp_app/webclients/chat_template_webclient.dart';
import 'package:unisinos_usp_app/webclients/chat_template_file_webclient.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:unisinos_usp_app/widgets/action_button.dart' as app_buttons;
import 'usp_plan_test.dart' show capture;
import 'evidence_path.dart' show publishEvidence;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('node links and agent text sources operate through UI',
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
    Future<void> settle() async =>
        tester.pumpAndSettle(const Duration(milliseconds: 500));
    Future<void> type(String label, String value) async {
      final field =
          find.byWidgetPredicate((w) => w is InputText && w.hintText == label);
      await tester.ensureVisible(field);
      await settle();
      await tester.enterText(field, value);
    }

    Future<void> save(String label) async {
      FocusManager.instance.primaryFocus?.unfocus();
      await settle();
      final button = find
          .ancestor(
              of: find.text(label).last,
              matching: find.byType(app_buttons.ActionButton))
          .first;
      await tester.ensureVisible(button);
      await settle();
      expect(
          tester
              .getRect(button)
              .overlaps(tester.getRect(find.byType(FloatingActionButton))),
          false);
      await tester.tap(button);
      await settle();
    }

    Future<void> select(String label, String name) async {
      final field = find
          .byWidgetPredicate((w) => w is InputSelectApi && w.label == label);
      await tester.ensureVisible(field);
      await tester.tap(field);
      await settle();
      await tester.tap(find.text(name).last);
      await settle();
    }

    final nodes = NodeWebclient(),
        links = NodeLinkWebclient(),
        templates = ChatTemplateWebclient(),
        sources = ChatTemplateFileWebclient();
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final nodeType = (await NodeTypeWebclient().fetch()).first;
    final ownNodes = <NodeModel>[];
    int? templateId;
    try {
      for (final letter in ['A', 'B', 'C']) {
        ownNodes.add(await nodes.create(NodeModel(
            id: 0,
            name: 'USP ligação $letter $suffix',
            nodeTypeId: nodeType.id,
            color: '#43D4C2')));
      }
      final a = ownNodes[0], b = ownNodes[1], c = ownNodes[2];
      Get.offAllNamed('/node_links');
      await settle();
      await tester.tap(find.byTooltip('Nova ligação'));
      await settle();
      await save('Salvar');
      expect(find.text('Obrigatório'), findsWidgets);
      await select('Nó de origem', a.name);
      await select('Nó de destino', a.name);
      await save('Salvar');
      expect(Uri.parse(Get.currentRoute).path, '/node_links/create');
      expect(
          (await links.fetch())
              .where((r) => r.sourceNodeId == a.id && r.targetNodeId == a.id),
          isEmpty);
      await select('Nó de destino', b.name);
      await capture(tester, 'node-link-create-form');
      await save('Salvar');
      final link = (await links.fetch())
          .singleWhere((r) => r.sourceNodeId == a.id && r.targetNodeId == b.id);
      Future<void> openLink() async {
        final title = find.text(a.name);
        await tester.scrollUntilVisible(title, 250,
            scrollable: find.byType(Scrollable).first, maxScrolls: 40);
        await settle();
        final row = find.ancestor(of: title, matching: find.byType(Card)).first;
        await tester.tap(
            find.descendant(of: row, matching: find.byIcon(Icons.edit)).first);
        await settle();
      }

      await openLink();
      await select('Nó de destino', c.name);
      await save('Atualizar');
      expect((await links.fetchById(link.id)).targetNodeId, c.id);
      await openLink();
      await select('Nó de destino', b.name);
      await tester.tap(find.byTooltip('Voltar').first);
      await settle();
      expect((await links.fetchById(link.id)).targetNodeId, c.id);
      final row = find
          .ancestor(of: find.text(a.name), matching: find.byType(Card))
          .first;
      await tester.ensureVisible(row);
      await capture(tester, 'node-link-edited');
      await tester.tap(find
          .descendant(of: row, matching: find.byIcon(Icons.delete_outline))
          .first);
      await settle();
      await tester.tap(find.text('Cancelar').last);
      await settle();
      expect((await links.fetchById(link.id)).targetNodeId, c.id);
      await tester.tap(find
          .descendant(of: row, matching: find.byIcon(Icons.delete_outline))
          .first);
      await settle();
      await tester.tap(find.text('Excluir').last);
      await settle();
      expect((await links.fetch()).any((r) => r.id == link.id), false);
      expect((await nodes.fetchById(a.id)).name, a.name);
      expect((await nodes.fetchById(c.id)).name, c.name);
      await capture(tester, 'node-link-deleted');
      final template = await templates.create(ChatTemplateModel(
          id: 0,
          name: 'USP fontes descartáveis $suffix',
          description: 'Agente sintético de teste',
          systemInstruction:
              'Responda com base nas fontes e reconheça dados ausentes.'));
      templateId = template.id;
      Get.offAllNamed('/chat_templates');
      await settle();
      final templateTitle = find.text(template.name);
      await tester.scrollUntilVisible(templateTitle, 250,
          scrollable: find.byType(Scrollable).first, maxScrolls: 40);
      await settle();
      final templateRow =
          find.ancestor(of: templateTitle, matching: find.byType(Card)).first;
      await tester.tap(find
          .descendant(of: templateRow, matching: find.byIcon(Icons.edit))
          .first);
      await settle();
      final add = find.text('Adicionar');
      await tester.ensureVisible(add);
      await tester.tap(add);
      await settle();
      await save('Salvar fonte');
      expect(find.text('Obrigatório'), findsWidgets);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await settle();
      await tester.tap(find.text('Texto').last);
      await settle();
      final sourceName = 'Fonte sintética $suffix';
      await type('Nome da fonte', sourceName);
      final content = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'Conteúdo');
      await tester.ensureVisible(content);
      await tester.enterText(content,
          'Observação fictícia: o exemplo contém 17 elementos, sem representar uma medição real.');
      await capture(tester, 'agent-source-text-form');
      await save('Salvar fonte');
      final source = (await sources.fetch(chatTemplateId: template.id))
          .singleWhere((r) => r.name == sourceName);
      expect(source.resolvedType, 'text');
      expect(
          source.originalContent ?? source.content, contains('17 elementos'));
      Get.offAllNamed('/chat_templates/update',
          parameters: {'id': '${template.id}'});
      await settle();
      final sourceRow = find
          .ancestor(of: find.text(sourceName), matching: find.byType(ListTile))
          .first;
      await tester.ensureVisible(sourceRow);
      await settle();
      await capture(tester, 'agent-source-text-persisted');
      await tester.tap(find.descendant(
          of: sourceRow, matching: find.byTooltip('Excluir fonte')));
      await settle();
      expect(
          (await sources.fetch(chatTemplateId: template.id))
              .any((r) => r.id == source.id),
          false);
      expect((await templates.fetchById(template.id)).name, template.name);
      await capture(tester, 'agent-source-text-deleted');
      await publishEvidence('relations-source-checks.json', {
        'status': 'aprovado',
        'node_links': {
          'required_validation': true,
          'self_link_rejected': true,
          'create': true,
          'edit': true,
          'cancel_edit': true,
          'cancel_delete': true,
          'delete_preserves_nodes': true
        },
        'agent_text_source': {
          'required_validation': true,
          'create': true,
          'persist_after_reopen': true,
          'delete_preserves_agent': true
        },
        'scope': 'actual UI operations; synthetic data; cleanup in finally'
      });
    } finally {
      final ownIds = ownNodes.map((n) => n.id).toSet();
      for (final link in await links.fetch()) {
        if (ownIds.contains(link.sourceNodeId) ||
            ownIds.contains(link.targetNodeId)) await links.delete(link.id);
      }
      for (final node in ownNodes) await nodes.delete(node.id);
      if (templateId != null) {
        for (final source in await sources.fetch(chatTemplateId: templateId))
          await sources.delete(source.id!);
        await templates.delete(templateId);
      }
    }
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 4)));
}
