import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:unisinos_usp_app/webclients/clue_connection_webclient.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/services/collection_service.dart';
import 'package:unisinos_usp_app/webclients/preferences_webclient.dart';
import 'package:unisinos_usp_app/webclients/category_webclient.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';

Future<void> capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('usp-app-screenshot-surface')));
  final image = await boundary.toImage();
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/usp-plan/$name.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(data!.buffer.asUint8List());
  image.dispose();
  final platform = Platform.isAndroid ? 'android' : 'linux';
  final response = await http.post(
      Uri.parse('http://127.0.0.1:8774/$platform/$name.png'),
      body: data.buffer.asUint8List());
  expect(response.statusCode, 201);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('USP catalog, collection, order and authenticated clue return',
      (tester) async {
    expect(Uri.parse(WebClient.apiBaseUrl).host, '127.0.0.1');
    await (await SharedPreferences.getInstance()).clear();
    await app.main();
    await tester.pump();
    for (var attempt = 0;
        attempt < 20 && find.byType(TextFormField).evaluate().length < 2;
        attempt++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    if (find.byType(TextFormField).evaluate().length < 2)
      await capture(tester, 'startup-state');
    expect(find.byType(TextFormField), findsNWidgets(2),
        reason:
            'The unauthenticated startup must reach login. Route: ${Get.currentRoute}');
    await tester.enterText(find.byType(TextFormField).at(0),
        const String.fromEnvironment('E2E_EMAIL'));
    await tester.enterText(find.byType(TextFormField).at(1),
        const String.fromEnvironment('E2E_PASSWORD'));
    await tester.tap(find.text('Entrar').last);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.text('Explore pistas e conexões'), findsOneWidget);
    await capture(tester, 'home');
    await PreferencesWebclient().setEditingEnabled(true);
    final service = CollectionService();
    final category = (await service.category(create: true))!;
    final itemCategory = (await CategoryWebclient().fetch())
        .firstWhere((c) => c.id != category.id);
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final cleanup = <int>[];
    try {
      Get.toNamed('/collections/create');
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byType(TextField).at(0), 'Coleção USP teste $suffix');
      await tester.enterText(find.byType(TextField).at(1),
          'Coleção inteiramente fictícia para validação.');
      await tester.ensureVisible(find.text('Salvar coleção'));
      await tester.tap(find.text('Salvar coleção'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.text('Itens da coleção'), findsOneWidget);
      final created =
          (await service.clues.fetch(search: 'Coleção USP teste $suffix'))
              .single;
      expect(Get.currentRoute, startsWith('/collections/show'));
      expect(Get.parameters['id'], '${created.id}',
          reason:
              'A saved collection must have a persistent address for reload.');
      cleanup.add(created.id);
      final first = await service.clues.create(LivingClueModel(
          id: 0,
          name: 'Item A $suffix',
          categoryId: itemCategory.id,
          metadata: {
            'typed': {'number': 3}
          },
          description: 'Texto sintético.'));
      final second = await service.clues.create(LivingClueModel(
          id: 0,
          name: 'Item B $suffix',
          categoryId: itemCategory.id,
          description: 'Outro texto sintético.'));
      cleanup.addAll([first.id, second.id]);
      await service.add(created, first.id);
      await service.add(created, second.id);
      await service.saveOrder(created.id, [second.id, first.id]);
      final reloaded = await service.clues.fetchById(created.id);
      expect((await service.items(reloaded)).map((i) => i.id),
          [second.id, first.id]);
      Get.offNamed('/collections/show', parameters: {'id': '${created.id}'});
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.text(first.name), findsOneWidget);
      await capture(tester, 'collection');
      await tester.ensureVisible(find.byTooltip('Mover para cima').last);
      await tester.tap(find.byTooltip('Mover para cima').last);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      final reordered = await service.clues.fetchById(created.id);
      expect((await service.items(reordered)).map((i) => i.id),
          [first.id, second.id]);
      // Adding after a move must retain the newly chosen order, not stale metadata.
      final third = await service.clues.create(LivingClueModel(
          id: 0, name: 'Item C $suffix', categoryId: itemCategory.id));
      cleanup.add(third.id);
      await tester.ensureVisible(find.text('Adicionar registro existente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adicionar registro existente'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, third.name);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.search).last);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await tester.tap(find.text(third.name).last);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      final appended = await service.clues.fetchById(created.id);
      expect((await service.items(appended)).map((item) => item.id),
          [first.id, second.id, third.id]);
      // The same record belongs to another collection without duplication.
      final other = await service.clues.create(LivingClueModel(
          id: 0, name: 'Outra coleção $suffix', categoryId: category.id));
      cleanup.add(other.id);
      await service.add(other, first.id);
      expect((await service.items(other)).single.id, first.id);
      await service.remove(created, first.id);
      expect((await service.clues.fetchById(first.id)).metadata, {
        'typed': {'number': 3}
      });
      Get.offAllNamed('/living_clues/show', parameters: {'id': '${first.id}'});
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.text(first.name), findsOneWidget);
      await capture(tester, 'clue');
      await tester.tap(find.byTooltip('QR Code'));
      await tester.pumpAndSettle();
      expect(find.text('QR Code da pista'), findsOneWidget);
      await capture(tester, 'qr');
      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();
      await Get.find<UserController>().logout();
      await tester.pumpAndSettle();
      Get.offAllNamed('/living_clues/show', parameters: {'id': '${first.id}'});
      await tester.pumpAndSettle();
      expect(Get.currentRoute, startsWith('/login'));
      expect(Get.parameters['return'], '/living_clues/show?id=${first.id}');
      await capture(tester, 'login-return');
      await tester.enterText(find.byType(TextFormField).at(0),
          const String.fromEnvironment('E2E_EMAIL'));
      await tester.enterText(find.byType(TextFormField).at(1),
          const String.fromEnvironment('E2E_PASSWORD'));
      await tester.tap(find.text('Entrar').last);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(Get.parameters['id'], '${first.id}');
      expect(find.text(first.name), findsOneWidget);
    } finally {
      final auth = await UserWebclient().login(
          mail: const String.fromEnvironment('E2E_EMAIL'),
          password: const String.fromEnvironment('E2E_PASSWORD'));
      await Get.find<UserController>().savePrefs(auth);
      for (final id in cleanup.reversed) {
        for (final link in await service.connections(id)) {
          // Clue deletion is soft; database FK cascades do not remove its links.
          expect(link['source_clue_id'] == id || link['target_clue_id'] == id,
              isTrue);
          await ClueConnectionWebclient().delete(link['id'] as int);
        }
        expect(await service.connections(id), isEmpty);
        await service.clues.delete(id);
      }
    }
  });
}
