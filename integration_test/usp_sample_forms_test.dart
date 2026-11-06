import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgets_spo/widgets_spo.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/widgets/cidig_date_form_field.dart';
import 'package:unisinos_usp_app/widgets/action_button.dart' as app_buttons;
import 'package:unisinos_usp_app/webclients/preferences_webclient.dart';
import 'package:unisinos_usp_app/webclients/sample_webclient.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'usp_plan_test.dart' show capture;
import 'evidence_path.dart' show publishEvidence;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'sample UI CRUD preserves date cancellation and exposes save controls',
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
    final client = SampleWebclient();
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final unique = 'usp-native-form-$suffix';
    final name = 'USP amostra nativa descartável $suffix';
    Finder textInput(String hint) =>
        find.byWidgetPredicate((w) => w is InputText && w.hintText == hint);
    Future<void> type(Finder field, String value) async {
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, value);
    }

    Future<void> waitRoute(String route) async {
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (Uri.parse(Get.currentRoute).path == route) break;
      }
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(Uri.parse(Get.currentRoute).path, route);
    }

    Future<void> save(String label) async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final button = find
          .ancestor(
              of: find.text(label).last,
              matching: find.byType(app_buttons.ActionButton))
          .first;
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      expect(
          tester
              .getRect(button)
              .overlaps(tester.getRect(find.byType(FloatingActionButton))),
          false,
          reason: 'The assistant must not obscure the save action.');
      await capture(tester,
          label == 'Salvar' ? 'sample-create-form' : 'sample-edit-form');
      await tester.tap(button);
      await waitRoute('/samples');
    }

    Future<void> edit(String title) async {
      final row =
          find.ancestor(of: find.text(title), matching: find.byType(ListTile));
      await tester.ensureVisible(row);
      await tester
          .tap(find.descendant(of: row, matching: find.byTooltip('Editar')));
      await waitRoute('/samples/update');
    }

    try {
      Get.offAllNamed('/samples');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await tester.tap(find.byTooltip('Novo'));
      await waitRoute('/samples/create');
      await type(textInput('Nome'), name);
      await type(textInput('Sample string'), 'Texto fictício');
      await type(textInput('Sample unique'), unique);
      await type(
          textInput('Nullable string (opcional)'), 'Valor opcional fictício');
      final detail = find.byWidgetPredicate(
          (w) => w is InputSelectApi && w.label == 'Sample detail');
      await tester.ensureVisible(detail);
      await tester.tap(detail);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await tester.tap(find.text('USP detalhe sintético'));
      await tester.pumpAndSettle();
      await type(
          find.byWidgetPredicate(
              (w) => w is InputNumber && w.label == 'Sample double'),
          '2.5');
      await tester.ensureVisible(find.byType(CidigDateFormField));
      await tester.tap(find.byType(CidigDateFormField));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.descendant(
              of: find.byType(DatePickerDialog),
              matching: find.byType(TextFormField)),
          '15/10/2026');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selecionar'));
      await tester.pumpAndSettle();
      expect(find.text('15/10/2026'), findsOneWidget);
      await save('Salvar');
      final created =
          (await client.fetch()).singleWhere((r) => r.sampleUnique == unique);
      expect(created.name, name);
      expect(created.sampleDouble, 2.5);
      expect([
        created.sampleDate.year,
        created.sampleDate.month,
        created.sampleDate.day
      ], [
        2026,
        10,
        15
      ]);
      await edit(name);
      await tester.ensureVisible(find.byType(CidigDateFormField));
      await tester.tap(find.byType(CidigDateFormField));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('15/10/2026'), findsOneWidget);
      await type(textInput('Nome'), '$name editada');
      await type(textInput('Nullable string (opcional)'), '');
      await type(
          find.byWidgetPredicate(
              (w) => w is InputNumber && w.label == 'Sample double'),
          '0');
      await save('Atualizar');
      final updated = await client.fetchById(created.id);
      expect(updated.name, '$name editada');
      expect(updated.sampleDouble, 0);
      expect(updated.nullableString?.isEmpty ?? true, true);
      expect([
        updated.sampleDate.year,
        updated.sampleDate.month,
        updated.sampleDate.day
      ], [
        2026,
        10,
        15
      ]);
      await edit(updated.name);
      await type(textInput('Nome'), 'Alteração cancelada no teste');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Voltar').first);
      await waitRoute('/samples');
      expect((await client.fetchById(created.id)).name, updated.name);
      final row = find.ancestor(
          of: find.text(updated.name), matching: find.byType(ListTile));
      await tester.ensureVisible(row);
      await tester
          .tap(find.descendant(of: row, matching: find.byTooltip('Excluir')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir').last);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      final deleted = await http.get(
          Uri.parse('${WebClient.apiBaseUrl}/sample_models/${created.id}'),
          headers: {'Authorization': 'Bearer ${auth.token}'});
      expect(deleted.statusCode, 404);
      await capture(tester, 'sample-deleted');
      await publishEvidence('sample-form-checks.json', {
        'status': 'aprovado',
        'explicit_zero_persisted': true,
        'operations': [
          'create',
          'edit',
          'cancel edit',
          'delete by confirmation'
        ],
        'date_picker': [
          'enter15/10/2026',
          'cancel preserves date',
          'saved date preserved after edit'
        ],
        'save_controls_clear_of_assistant': true,
        'deleted_status': 404,
      });
    } finally {
      for (final row
          in (await client.fetch()).where((r) => r.sampleUnique == unique)) {
        await client.delete(row.id);
      }
    }
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 4)));
}
