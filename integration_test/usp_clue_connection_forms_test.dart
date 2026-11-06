import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgets_spo/widgets_spo.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/models/connection_type_model.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';
import 'package:unisinos_usp_app/webclients/category_webclient.dart';
import 'package:unisinos_usp_app/webclients/clue_connection_webclient.dart';
import 'package:unisinos_usp_app/webclients/connection_type_webclient.dart';
import 'package:unisinos_usp_app/webclients/preferences_webclient.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:unisinos_usp_app/widgets/action_button.dart' as actions;
import 'usp_plan_test.dart' show capture;
import 'evidence_path.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'direct clue connection forms preserve endpoints and cancellation',
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
    final clues = LivingClueWebclient();
    final connections = ClueConnectionWebclient();
    final types = ConnectionTypeWebclient();
    final own = <LivingClueModel>[];
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final evidence = 'USP conexão descartável $suffix';
    final category = (await CategoryWebclient().fetch()).first;
    final type = await types
        .create(ConnectionTypeModel(id: 0, name: 'USP relação $suffix'));
    Future<void> settle() =>
        tester.pumpAndSettle(const Duration(milliseconds: 500));
    Future<void> save(String label) async {
      FocusManager.instance.primaryFocus?.unfocus();
      await settle();
      final button = find
          .ancestor(
              of: find.text(label).last,
              matching: find.byType(actions.ActionButton))
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

    Future<void> select(String hint, String name) async {
      final input =
          find.byWidgetPredicate((w) => w is InputSelectApi && w.hint == hint);
      await tester.ensureVisible(input);
      await tester.tap(input);
      await settle();
      await tester.enterText(find.byType(TextField).last, name);
      await tester.pump(const Duration(milliseconds: 700));
      await settle();
      await tester.tap(find.text(name).last);
      await settle();
    }

    Future<void> typeEvidence(String value) async {
      final input = find.byWidgetPredicate(
          (w) => w is InputText && w.hintText == 'Evidência (opcional)');
      await tester.ensureVisible(input);
      await tester.enterText(input, value);
      await settle();
    }

    Future<void> strength(String value) async {
      final input =
          find.byWidgetPredicate((w) => w is InputNumber && w.label == 'Força');
      await tester.ensureVisible(input);
      await tester.enterText(input, value);
      await settle();
    }

    Finder row() => find
        .ancestor(
            of: find.textContaining(evidence).first,
            matching: find.byType(Card))
        .first;
    Future<void> openOwn() async {
      await tester.scrollUntilVisible(find.textContaining(evidence), 250,
          scrollable: find.byType(Scrollable).first, maxScrolls: 60);
      await settle();
      await tester
          .tap(find.descendant(of: row(), matching: find.byTooltip('Editar')));
      await settle();
    }

    try {
      for (final letter in ['A', 'B', 'C']) {
        own.add(await clues.create(LivingClueModel(
            id: 0,
            name: 'USP vínculo $letter $suffix',
            categoryId: category.id,
            description: 'Registro sintético descartável.')));
      }
      Get.offAllNamed('/clue_connections/update');
      await settle();
      expect(find.text('Conexão não informada.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      Get.offAllNamed('/clue_connections');
      await settle();
      await tester.tap(find.byTooltip('Nova conexão'));
      await settle();
      await save('Salvar');
      expect(find.text('Obrigatório'), findsWidgets);
      await select('Pista origem', own[0].name);
      await select('Pista destino', own[0].name);
      await select('Tipo de conexão', type.name);
      await save('Salvar');
      expect(Uri.parse(Get.currentRoute).path, '/clue_connections/create');
      await select('Pista destino', own[1].name);
      await typeEvidence(evidence);
      await strength('2');
      await save('Salvar');
      final connection = (await connections.fetch())
          .singleWhere((c) => c.evidence == evidence);
      expect(connection.sourceClueId, own[0].id);
      expect(connection.targetClueId, own[1].id);
      expect(connection.strength, 2);
      await openOwn();
      await select('Pista destino', own[2].name);
      await strength('3');
      await save('Atualizar');
      final edited = await connections.fetchById(connection.id);
      expect(edited.targetClueId, own[2].id);
      expect(edited.strength, 3);
      await capture(tester, 'clue-connection-edited');
      await openOwn();
      await typeEvidence('');
      await strength('0');
      await save('Atualizar');
      final cleared = await connections.fetchById(connection.id);
      expect(cleared.evidence?.isEmpty ?? true, true);
      expect(cleared.strength, 0);
      Get.toNamed('/clue_connections/update?id=${connection.id}');
      await settle();
      await typeEvidence(evidence);
      await strength('3');
      await save('Atualizar');
      Get.offAllNamed('/clue_connections');
      await settle();

      await openOwn();
      await typeEvidence('Rascunho cancelado');
      FocusManager.instance.primaryFocus?.unfocus();
      await settle();
      await tester.tap(find.byTooltip('Voltar').first);
      await settle();
      expect((await connections.fetchById(connection.id)).evidence, evidence);
      await tester.ensureVisible(row());
      await tester
          .tap(find.descendant(of: row(), matching: find.byTooltip('Excluir')));
      await settle();
      await tester.tap(find.text('Cancelar').last);
      await settle();
      expect(
          (await connections.fetchById(connection.id)).targetClueId, own[2].id);
      await tester
          .tap(find.descendant(of: row(), matching: find.byTooltip('Excluir')));
      await settle();
      await tester.tap(find.text('Excluir').last);
      await settle();
      expect(
          (await connections.fetch()).any((c) => c.id == connection.id), false);
      for (final clue in own) {
        expect((await clues.fetchById(clue.id)).name, clue.name);
      }
      expect(tester.takeException(), isNull);
      await capture(tester, 'clue-connection-deleted');
      await publishEvidence('clue-connection-form-checks.json', {
        'status': 'aprovado no escopo descrito',
        'required_validation': true,
        'missing_id_safe': true,
        'self_link_refused': true,
        'ui_create': true,
        'ui_edit_target_and_strength': true,
        'explicit_zero_and_empty_evidence_persisted': true,
        'cancel_edit': true,
        'cancel_delete': true,
        'ui_delete_preserves_clues': true,
        'cleanup_scope': 'own clues, type and any links only; finally block'
      });
    } finally {
      final ids = own.map((c) => c.id).toSet();
      for (final link in await connections.fetch()) {
        if (ids.contains(link.sourceClueId) ||
            ids.contains(link.targetClueId)) {
          await connections.delete(link.id);
        }
      }
      for (final clue in own) {
        await clues.delete(clue.id);
      }
      await types.delete(type.id);
    }
  });
}
