import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgets_spo/widgets_spo.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/controllers/node_graph/node_graph_controller.dart';
import 'package:unisinos_usp_app/models/node_model.dart';
import 'package:unisinos_usp_app/webclients/node_webclient.dart';
import 'package:unisinos_usp_app/webclients/node_link_webclient.dart';
import 'package:unisinos_usp_app/webclients/node_type_webclient.dart';
import 'package:unisinos_usp_app/webclients/preferences_webclient.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'usp_plan_test.dart' show capture;
import 'evidence_path.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('graph UI edits, dragging, filtering and deletion persist',
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
    final client = NodeWebclient();
    final type = (await NodeTypeWebclient().fetch()).first;
    final name =
        'USP grafo descartável ${DateTime.now().microsecondsSinceEpoch}';
    final own = await client.create(NodeModel(
        id: 0,
        name: name,
        color: '#43D4C2',
        nodeTypeId: type.id,
        x: -70,
        y: -65));
    var deleted = false;
    int? childId;
    Future<void> settle() =>
        tester.pumpAndSettle(const Duration(milliseconds: 500));
    Future<void> tapText(String label) async {
      final f = find.text(label).last;
      await tester.ensureVisible(f);
      await settle();
      await tester.tap(f);
      await settle();
      expect(tester.takeException(), isNull, reason: label);
      if (Get.isBottomSheetOpen ?? false) {
        expect(find.byType(FloatingActionButton), findsNothing, reason: label);
      }
    }

    final previousHitTestPolicy = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    try {
      Get.offAllNamed('/nodes/graph');
      await settle();
      final graph = Get.find<NodeGraphController>();
      expect(find.text(name), findsOneWidget);
      await tester.drag(find.text(name), const Offset(32, 24));
      await settle();
      final moved = await client.fetchById(own.id);
      expect(((moved.x ?? -70) + 70).abs() + ((moved.y ?? -65) + 65).abs(),
          greaterThan(1));
      await tester.tap(find.byTooltip('Recarregar'));
      await settle();
      final state = graph.graphNodes.firstWhere((n) => n.node.id == own.id);
      expect(state.position.dx, closeTo(moved.x!, .1));
      expect(state.position.dy, closeTo(moved.y!, .1));
      await tester.tap(find.text(name));
      await settle();
      await tapText('Editar');
      final input = find.byWidgetPredicate(
          (w) => w is InputText && w.hintText == 'Nome do nó');
      await tester.ensureVisible(input);
      await tester.tap(input);
      await tester.enterText(input, '$name editado');
      FocusManager.instance.primaryFocus?.unfocus();
      await settle();
      await tapText('Salvar alterações');
      expect((await client.fetchById(own.id)).name, '$name editado');
      await capture(tester, 'graph-node-edited');
      await tapText('Editar');
      await tester.ensureVisible(input);
      await tester.tap(input);
      await tester.enterText(input, 'Rascunho cancelado');
      FocusManager.instance.primaryFocus?.unfocus();
      await settle();
      await tapText('Cancelar');
      expect((await client.fetchById(own.id)).name, '$name editado');
      await tapText('Novo nó próximo');
      await tester.ensureVisible(input);
      await tester.tap(input);
      await tester.enterText(input, '$name próximo');
      FocusManager.instance.primaryFocus?.unfocus();
      await settle();
      await tapText('Criar nó');
      final child = (await client.fetch(search: '$name próximo'))
          .singleWhere((n) => n.name == '$name próximo');
      childId = child.id;
      await tester.tap(find.byTooltip('Fechar seleção'));
      await settle();
      await tester.tap(find.text('$name editado').first);
      await settle();
      await tapText('Conectar');
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await settle();
      await tester.tap(find.text('$name próximo').last);
      await settle();
      await tapText('Criar ligação');
      expect(
          graph.graphLinks.any((l) =>
              (l.sourceNodeId == own.id && l.targetNodeId == child.id) ||
              (l.targetNodeId == own.id && l.sourceNodeId == child.id)),
          true);
      await tester.tap(find.byTooltip('Recarregar'));
      await settle();
      expect(
          graph.graphLinks.any((l) =>
              (l.sourceNodeId == own.id && l.targetNodeId == child.id) ||
              (l.targetNodeId == own.id && l.sourceNodeId == child.id)),
          true);
      await tapText('Conexões');
      await capture(tester, 'graph-link-created');
      await tapText('Remover');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Remover'));
      await settle();
      expect(
          graph.graphLinks
              .any((l) => l.sourceNodeId == own.id || l.targetNodeId == own.id),
          false);
      expect((await client.fetchById(child.id)).name, '$name próximo');
      await tapText('Fechar');
      final filter = find.widgetWithText(FilterChip, type.name);
      await tester.tap(filter);
      await settle();
      expect(graph.visibleNodes.any((n) => n.node.id == own.id), false);
      await tester.tap(filter);
      await settle();
      expect(graph.visibleNodes.any((n) => n.node.id == own.id), true);
      await tester.tap(find.text('$name editado').first);
      await settle();
      await tapText('Excluir');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Excluir'));
      await settle();
      expect((await client.fetch(search: name)).where((n) => n.id == own.id),
          isEmpty);
      deleted = true;
      await capture(tester, 'graph-node-deleted');
      expect(tester.takeException(), isNull);
      await publishEvidence('graph-interaction-checks.json', {
        'status': 'aprovado no escopo descrito',
        'fixture': 'own disposable synthetic node',
        'drag_persisted': true,
        'reload_position': true,
        'edit': true,
        'cancel_edit': true,
        'filter': true,
        'create_near': true,
        'link_create_reload': true,
        'link_remove_preserves_nodes': true,
        'delete': true,
        'cleanup': true,
        'scope': 'Graph nodes and links; zoom has separate coverage.'
      });
    } finally {
      WidgetController.hitTestWarningShouldBeFatal = previousHitTestPolicy;
      // Node deletion is soft; remove only links involving this run's own IDs.
      final linksClient = NodeLinkWebclient();
      final ownedLinkIds = <int>[];
      for (var offset = 0;; offset += 100) {
        final page = await linksClient.fetch(limit: 100, offset: offset);
        ownedLinkIds.addAll(page
            .where((link) =>
                link.sourceNodeId == own.id ||
                link.targetNodeId == own.id ||
                (childId != null &&
                    (link.sourceNodeId == childId ||
                        link.targetNodeId == childId)))
            .map((link) => link.id));
        if (page.length < 100) break;
      }
      for (final id in ownedLinkIds) {
        await linksClient.delete(id);
      }
      if (childId != null) await client.delete(childId);
      if (!deleted) await client.delete(own.id);
    }
  });
}
