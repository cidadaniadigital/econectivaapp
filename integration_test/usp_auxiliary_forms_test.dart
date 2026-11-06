import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgets_spo/widgets_spo.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:unisinos_usp_app/webclients/preferences_webclient.dart';
import 'package:unisinos_usp_app/webclients/category_webclient.dart';
import 'package:unisinos_usp_app/webclients/connection_type_webclient.dart';
import 'package:unisinos_usp_app/webclients/node_type_webclient.dart';
import 'package:unisinos_usp_app/webclients/node_webclient.dart';
import 'package:unisinos_usp_app/webclients/chat_template_webclient.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:unisinos_usp_app/widgets/action_button.dart' as app_buttons;
import 'usp_plan_test.dart' show capture;
import 'evidence_path.dart' show publishEvidence;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('auxiliary category and type forms complete UI CRUD',
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
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final cases = <Map<String, dynamic>>[
      {
        'route': 'categories',
        'new': 'Nova categoria',
        'client': CategoryWebclient()
      },
      {
        'route': 'connection_types',
        'new': 'Novo tipo',
        'client': ConnectionTypeWebclient()
      },
      {
        'route': 'node_types',
        'new': 'Novo tipo',
        'client': NodeTypeWebclient()
      },
      {'route': 'nodes', 'new': 'Novo nó', 'client': NodeWebclient()},
      {
        'route': 'chat_templates',
        'new': 'Novo agente',
        'client': ChatTemplateWebclient()
      },
      {'route': 'users', 'new': 'Novo usuário', 'client': _UserCrudClient()},
    ];
    final results = <Map<String, dynamic>>[];
    Finder input(String label) =>
        find.byWidgetPredicate((w) => w is InputText && w.hintText == label);
    Future<void> type(String label, String value) async {
      await tester.ensureVisible(input(label));
      await tester.pumpAndSettle();
      await tester.enterText(input(label), value);
    }

    Future<void> settle() async {
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
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

    for (final entry in cases) {
      final route = entry['route'] as String;
      final dynamic client = entry['client'];
      final name = 'USP UI $route $suffix';
      final ownEmail = 'usp-native-user-$suffix@example.test';
      final ownPassword = List.generate(24,
              (_) => 'Aa0!xyzQWERTYUIOP123456789'[Random.secure().nextInt(25)])
          .join();
      int? ownId;
      Future<void> openEdit(String title) async {
        if (route == 'users') {
          final search = find.byWidgetPredicate((w) =>
              w is TextField &&
              w.decoration?.hintText == 'Buscar por nome ou e-mail');
          await tester.enterText(search, ownEmail);
          await tester.testTextInput.receiveAction(TextInputAction.search);
          FocusManager.instance.primaryFocus?.unfocus();
          await settle();
        }
        await tester.scrollUntilVisible(find.text(title), 250,
            scrollable: find.byType(Scrollable).first, maxScrolls: 40);
        await settle();
        final row = find
            .ancestor(
                of: find.text(title),
                matching: route == 'categories'
                    ? find.byType(ListTile)
                    : find.byType(Card))
            .first;
        await tester.tap(
            find.descendant(of: row, matching: find.byIcon(Icons.edit)).first);
        await settle();
      }

      try {
        Get.offAllNamed('/$route');
        await settle();
        await tester.tap(find.byTooltip(entry['new'] as String));
        await settle();
        expect(Uri.parse(Get.currentRoute).path, '/$route/create');
        await save('Salvar');
        expect(find.text('Obrigatório'), findsWidgets);
        await type('Nome', name);
        if (route == 'categories') {
          await tester.tap(find.byType(DropdownButtonFormField<String>));
          await settle();
          await tester.tap(find.text('Pista Viva').last);
          await settle();
          await type('Cor em hex (ex: #FF5733)', '#43D4C2');
          await type('Metadata tags (ex: tag_teste,tag_other)', 'teste_usp');
        } else if (route == 'connection_types') {
          await type('Estilo de linha (solid/dashed/dotted)', 'dashed');
          await tester.tap(find.byType(SwitchListTile));
          await settle();
        } else if (route == 'users') {
          await type('E-mail', ownEmail);
          await type('Telefone', '00000000000');
          await type('Senha', ownPassword);
        } else if (route == 'nodes') {
          final selector = find.byWidgetPredicate(
              (w) => w is InputSelectApi && w.label == 'Tipo de nó');
          await tester.ensureVisible(selector);
          await tester.tap(selector);
          await settle();
          await tester.tap(find.text('USP problemática sintética'));
          await settle();
          await type('Cor hexadecimal', '#43D4C2');
        } else if (route == 'chat_templates') {
          for (final label in ['Descrição', 'System instruction']) {
            final field = find.byWidgetPredicate(
                (w) => w is TextField && w.decoration?.hintText == label);
            await tester.ensureVisible(field);
            await settle();
            await tester.enterText(
                field,
                label == 'Descrição'
                    ? 'Agente fictício descartável'
                    : 'Responda em português e reconheça dados ausentes.');
          }
        } else {
          await type('Cor hexadecimal', '#43D4C2');
        }
        await capture(tester, '${route.replaceAll('_', '-')}-create-form');
        await save('Salvar');
        expect(Uri.parse(Get.currentRoute).path, '/$route');
        final List<dynamic> records = await client.fetch();
        final dynamic created =
            records.singleWhere((dynamic r) => r.name == name);
        ownId = created.id as int;
        if (route == 'users') {
          expect(created.email, ownEmail);
          expect(created.profile, 10);
          expect(created.phone, '00000000000');
        }
        if (route == 'categories') {
          expect(created.type, 'Pista Viva');
          expect(created.metadataTags, 'teste_usp');
        }
        if (route == 'connection_types') {
          expect(created.isDirectional, false);
          expect(created.strokeStyle, 'dashed');
        }
        if (route == 'node_types') expect(created.color, '#43D4C2');
        if (route == 'nodes') {
          expect(created.color, '#43D4C2');
          expect(created.nodeTypeId, greaterThan(0));
        }
        if (route == 'chat_templates') {
          expect(created.description, 'Agente fictício descartável');
          expect(created.systemInstruction,
              'Responda em português e reconheça dados ausentes.');
        }
        await openEdit(name);
        await type('Nome', '$name editado');
        if (route == 'users') await type('Telefone', '');
        await save('Atualizar');
        expect((await client.fetchById(ownId)).name, '$name editado');
        if (route == 'users') {
          expect((await client.fetchById(ownId)).phone ?? '', '');
          final login = await UserWebclient()
              .login(mail: ownEmail, password: ownPassword);
          expect(login.id, ownId,
              reason: 'Leaving the optional password empty must retain login.');
        }
        await openEdit('$name editado');
        await type('Nome', 'Rascunho cancelado');
        FocusManager.instance.primaryFocus?.unfocus();
        await settle();
        await tester.tap(find.byTooltip('Voltar').first);
        await settle();
        expect((await client.fetchById(ownId)).name, '$name editado');
        await tester.scrollUntilVisible(find.text('$name editado'), 250,
            scrollable: find.byType(Scrollable).first, maxScrolls: 40);
        await settle();
        final tile = find
            .ancestor(
                of: find.text('$name editado'),
                matching: route == 'categories'
                    ? find.byType(ListTile)
                    : find.byType(Card))
            .first;
        await tester.ensureVisible(tile);
        await settle();
        await capture(tester, '${route.replaceAll('_', '-')}-edited');
        await tester.tap(find
            .descendant(of: tile, matching: find.byIcon(Icons.delete_outline))
            .first);
        await settle();
        await tester.tap(find.text('Cancelar').last);
        await settle();
        expect((await client.fetchById(ownId)).name, '$name editado');
        await tester.tap(find
            .descendant(of: tile, matching: find.byIcon(Icons.delete_outline))
            .first);
        await settle();
        await tester.tap(find.text('Excluir').last);
        await settle();
        final List<dynamic> after = await client.fetch();
        expect(after.any((dynamic r) => r.id == ownId), false);
        await capture(tester, '${route.replaceAll('_', '-')}-deleted');
        results.add({
          'route': route,
          'status': 'aprovado',
          'create_validation': true,
          'create': true,
          'edit': true,
          'cancel_edit': true,
          'cancel_delete': true,
          'delete': true,
          'cleanup': true
        });
      } finally {
        final List<dynamic> remaining = await client.fetch();
        for (final dynamic item in remaining.where(
            (dynamic r) => r.name == name || r.name == '$name editado')) {
          await client.delete(item.id);
        }
      }
      if (route == 'users') {
        final search = find.byWidgetPredicate((w) =>
            w is TextField &&
            w.decoration?.hintText == 'Buscar por nome ou e-mail');
        await tester.enterText(search, '');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        FocusManager.instance.primaryFocus?.unfocus();
        await settle();
      }
      for (var attempt = 0; attempt < 12; attempt++) {
        final state =
            tester.state<ScrollableState>(find.byType(Scrollable).first);
        if (state.position.pixels >= state.position.maxScrollExtent) break;
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
        await settle();
      }
      final lastDelete = find.byIcon(Icons.delete_outline).last;
      expect(lastDelete, findsOneWidget);
      final deleteButton = find
          .ancestor(of: lastDelete, matching: find.byType(IconButton))
          .first;
      expect(
          tester
              .getRect(deleteButton)
              .overlaps(tester.getRect(find.byType(FloatingActionButton))),
          false,
          reason:
              'The final row action must be reachable clear of the assistant.');
      await capture(tester, '${route.replaceAll('_', '-')}-list-bottom');
      expect(tester.takeException(), isNull);
    }
    await publishEvidence('auxiliary-form-checks.json', {
      'status': 'aprovado',
      'rows': results,
      'scope': 'actual UI form operations; isolated API'
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}

class _UserCrudClient {
  final _client = UserWebclient();
  Future<List<dynamic>> fetch() => _client.fetchUsers();
  Future<dynamic> fetchById(int id) => _client.fetchUserById(id);
  Future<void> delete(int id) => _client.deleteUser(id);
}
