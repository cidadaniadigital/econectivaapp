import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/models/user_model.dart';
import 'package:unisinos_usp_app/services/collection_service.dart';
import 'package:unisinos_usp_app/webclients/preferences_webclient.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'usp_plan_test.dart' show capture;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'environment, readings and participant permission boundaries on isolated API',
      (tester) async {
    expect(Uri.parse(WebClient.apiBaseUrl).host, '127.0.0.1');
    await (await SharedPreferences.getInstance()).clear();
    await app.main();
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    final users = UserWebclient();
    final admin = await users.login(
        mail: const String.fromEnvironment('E2E_EMAIL'),
        password: const String.fromEnvironment('E2E_PASSWORD'));
    await Get.find<UserController>().savePrefs(admin);
    Future<void> open(int id) async {
      expect(id, greaterThan(0));
      Get.offAllNamed('/living_clues/show', parameters: {'id': '$id'});
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    await open(const int.fromEnvironment('E2E_PLANT_ID'));
    for (final label in [
      'Bioma',
      'Cobertura predominante',
      'Vegetação no entorno',
      'Distância até água',
      'Altitude',
      'Declividade',
      'Área construída no entorno',
      'Densidade populacional'
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('0,00 %'), findsOneWidget);
    expect(find.textContaining('Fonte sintética'), findsWidgets);
    expect(find.textContaining('DADOS FICTÍCIOS'), findsOneWidget);
    expect(find.textContaining('unidade não informada'), findsWidgets);
    expect(find.textContaining('há '), findsWidgets);
    await tester.ensureVisible(find.text('Contexto ambiental'));
    await tester.pumpAndSettle();
    await capture(tester, 'environment');
    await tester.ensureVisible(find.text('Leituras recentes'));
    await tester.pumpAndSettle();
    await capture(tester, 'readings');
    await open(const int.fromEnvironment('E2E_PENDING_ID'));
    expect(find.text('Análise pendente.'), findsOneWidget);
    await open(const int.fromEnvironment('E2E_STALE_ID'));
    expect(
        find.text(
            'A análise disponível corresponde a outra localização. Aguardando contexto atualizado.'),
        findsOneWidget);
    expect(find.text('Bioma fictício'), findsNothing);
    await open(const int.fromEnvironment('E2E_FAILED_ID'));
    expect(find.text('Não foi possível obter o contexto ambiental.'),
        findsOneWidget);
    await open(const int.fromEnvironment('E2E_PARTIAL_ID'));
    expect(find.text('0,00 %'), findsOneWidget);
    expect(find.text('Não informado'), findsWidgets);
    await open(const int.fromEnvironment('E2E_SENSOR_ID'));
    expect(find.text('Sem localização informada.'), findsOneWidget);
    expect(find.textContaining('Nenhuma leitura disponível'), findsOneWidget);
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final password = 'Synthetic-only-$suffix-Aa!';
    final participant = await users.createUser(UserModel(
        id: 0,
        name: 'USP participante fictício',
        email: 'usp-permissions-$suffix@example.test',
        profile: 10,
        password: password));
    try {
      final auth =
          await users.login(mail: participant.email, password: password);
      await Get.find<UserController>().savePrefs(auth);
      await PreferencesWebclient().setEditingEnabled(false);
      await open(const int.fromEnvironment('E2E_PLANT_ID'));
      expect(find.byTooltip('Editar pista'), findsNothing);
      expect(find.text('Conectar a outra pista'), findsNothing);
      expect(find.text('Adicionar anexo'), findsNothing);
      expect(find.byTooltip('Excluir anexo'), findsNothing);
      expect(find.text('Abrir conversa'), findsOneWidget);
      await capture(tester, 'participant-clue');
      Get.offAllNamed('/collections/show', parameters: {
        'id': '${const int.fromEnvironment('E2E_COLLECTION_ID')}'
      });
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.byTooltip('Editar coleção'), findsNothing);
      expect(find.text('Adicionar registro existente'), findsNothing);
      await capture(tester, 'participant-collection');
      await expectLater(
          CollectionService()
              .saveOrder(const int.fromEnvironment('E2E_COLLECTION_ID'), []),
          throwsA(contains('Ative criação e edição')));
      Get.toNamed('/users');
      await tester.pumpAndSettle();
      expect(Get.currentRoute, '/home');
      await expectLater(
          users.fetchUsers(limit: 1), throwsA(contains('permissão')));
      Get.toNamed('/collections/create');
      await tester.pumpAndSettle();
      expect(find.text('Salvar coleção'), findsNothing);
      expect(find.textContaining('Ative criação e edição'), findsOneWidget);
      Get.offAllNamed('/living_clues/update',
          parameters: {'id': '${const int.fromEnvironment('E2E_PLANT_ID')}'});
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.text('Criação e edição desativadas.'), findsOneWidget);
      expect(find.text('Salvar'), findsNothing);
      await capture(tester, 'participant-direct-edit-blocked');
      await tester.tap(find.text('Meu perfil'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await tester.tap(find.text('Criação e edição'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await tester.tap(find.byTooltip('Voltar').first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(
          Get.parameters['id'], '${const int.fromEnvironment('E2E_PLANT_ID')}');
      expect(find.text('Editar pista viva'), findsOneWidget);
      expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField).first)
              .controller
              ?.text,
          'USP piloto — planta fictícia');
      await capture(tester, 'participant-edit-enabled-return');
    } finally {
      await Get.find<UserController>().savePrefs(admin);
      await users.deleteUser(participant.id);
    }
    expect(tester.takeException(), isNull);
  });
}
