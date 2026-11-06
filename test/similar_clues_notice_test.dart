import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:widgets_spo/services/auth_provider.dart';
import 'package:unisinos_usp_app/services/auth_user.dart';
import 'package:unisinos_usp_app/services/user_auth_service.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/widgets/similar_clues_notice.dart';

LivingClueModel clue(String name) => LivingClueModel(
      id: 12,
      name: name,
      categoryId: 1,
      description: 'Uma descrição existente.',
    );

Future<void> mount(
  WidgetTester tester,
  TextEditingController name,
  SimilarCluesSearch search,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: name),
              SimilarCluesNotice(nameController: name, search: search),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('waits for three characters and pauses typing before searching', (
    tester,
  ) async {
    final name = TextEditingController();
    addTearDown(name.dispose);
    final calls = <String>[];
    await mount(tester, name, (query) async {
      calls.add(query);
      return [];
    });
    name.text = 'ab';
    await tester.pump(const Duration(seconds: 1));
    expect(calls, isEmpty);
    name.text = '  Educação   digital ';
    await tester.pump(const Duration(milliseconds: 400));
    name.text = 'Educação digital viva';
    await tester.pump(const Duration(milliseconds: 599));
    expect(calls, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(calls, ['Educação digital viva']);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('stale results cannot replace the current name search', (
    tester,
  ) async {
    final name = TextEditingController();
    addTearDown(name.dispose);
    final pending = <String, Completer<List<LivingClueModel>>>{};
    await mount(
      tester,
      name,
      (q) => (pending[q] = Completer<List<LivingClueModel>>()).future,
    );
    name.text = 'Primeira';
    await tester.pump(const Duration(milliseconds: 600));
    name.text = 'Segunda';
    await tester.pump(const Duration(milliseconds: 600));
    pending['Segunda']!.complete([clue('Resultado atual')]);
    await tester.pump();
    pending['Primeira']!.complete([clue('Resultado antigo')]);
    await tester.pump();
    expect(find.text('Resultado atual'), findsOneWidget);
    expect(find.text('Resultado antigo'), findsNothing);
    name.clear();
    await tester.pump();
    expect(find.text('Resultado atual'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'preview and dismiss preserve the draft and cap results at five',
    (tester) async {
      final name = TextEditingController();
      addTearDown(name.dispose);
      await mount(
        tester,
        name,
        (q) async => List.generate(8, (i) => clue('Pista $i')),
      );
      name.text = 'Pista';
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      expect(find.text('Pista 4'), findsOneWidget);
      expect(find.text('Pista 5'), findsNothing);
      await tester.tap(find.text('Pista 0'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Uma descrição existente.'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Voltar ao cadastro'));
      await tester.pumpAndSettle();
      expect(name.text, 'Pista');
      await tester.ensureVisible(find.text('Continuar com uma nova pista'));
      await tester.tap(find.text('Continuar com uma nova pista'));
      await tester.pump();
      expect(find.text('Encontramos pistas semelhantes'), findsNothing);
      expect(name.text, 'Pista');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('search errors are advisory and retryable', (tester) async {
    final name = TextEditingController();
    addTearDown(name.dispose);
    var calls = 0;
    await mount(tester, name, (q) async {
      if (++calls == 1) throw StateError('offline');
      return [clue('Recuperada')];
    });
    name.text = 'Pista';
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(
      find.textContaining('Você pode continuar o cadastro.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Recuperada'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('disposing cancels debounce and ignores pending requests', (
    tester,
  ) async {
    final name = TextEditingController();
    addTearDown(name.dispose);
    var calls = 0;
    final pending = Completer<List<LivingClueModel>>();
    await mount(tester, name, (q) {
      calls++;
      return pending.future;
    });
    name.text = 'Nome';
    await tester.pump(const Duration(milliseconds: 600));
    name.text = 'Outro';
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete([clue('Tardia')]);
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('default search uses only Atopos API with five results',
      (tester) async {
    final auth = UserAuthService()
      ..setUser(const AuthUser(
          id: 1,
          name: 'Teste',
          email: 'test@example.test',
          token: 'synthetic'));
    AuthProvider.register(auth);
    final original = WebClient.instance.client;
    addTearDown(() => WebClient.instance.client = original);
    final requests = <Uri>[];
    WebClient.instance.client = MockClient((request) async {
      requests.add(request.url);
      return http.Response(
          jsonEncode([
            {'id': 12, 'name': 'Pista existente', 'category_id': 1}
          ]),
          200);
    });
    final name = TextEditingController();
    addTearDown(name.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SimilarCluesNotice(nameController: name))));
    name.text = 'Pista';
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(requests, hasLength(1));
    expect(requests.single.host, 'api.atopos.spotec.app');
    expect(requests.single.path, '/api/living_clues');
    expect(requests.single.queryParameters, containsPair('search', 'Pista'));
    expect(requests.single.queryParameters, containsPair('limit', '5'));
    expect(find.text('Pista existente'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Atopos detail navigation preserves every draft field on return',
      (tester) async {
    Get.testMode = true;
    addTearDown(Get.reset);
    final name = TextEditingController();
    addTearDown(name.dispose);
    final drafts =
        List.generate(5, (i) => TextEditingController(text: 'Rascunho $i'));
    for (final c in drafts) {
      addTearDown(c.dispose);
    }
    await tester.pumpWidget(GetMaterialApp(
      getPages: [
        GetPage(
            name: '/living_clues/show',
            page: () => Scaffold(
                    body: Column(children: [
                  Text('Detalhe ${Get.parameters['id']}'),
                  TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Retornar')),
                ])))
      ],
      home: Scaffold(
          body: SingleChildScrollView(
              child: Column(children: [
        TextField(controller: name),
        SimilarCluesNotice(
            nameController: name, search: (_) async => [clue('Existente')]),
        for (final c in drafts) TextField(controller: c),
      ]))),
    ));
    name.text = 'Minha pista';
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Existente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver pista completa'));
    await tester.pumpAndSettle();
    expect(find.text('Detalhe 12'), findsOneWidget);
    await tester.tap(find.text('Retornar'));
    await tester.pumpAndSettle();
    expect(name.text, 'Minha pista');
    for (var i = 0; i < drafts.length; i++) {
      expect(drafts[i].text, 'Rascunho $i');
    }
    expect(find.text('Existente'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('suggestions fit a narrow mobile layout', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final name = TextEditingController();
    addTearDown(name.dispose);
    await mount(
        tester,
        name,
        (_) async => [
              clue(
                  'Um título longo de pista para conferir em uma tela estreita')
            ]);
    name.text = 'Título';
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Encontramos pistas semelhantes'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
