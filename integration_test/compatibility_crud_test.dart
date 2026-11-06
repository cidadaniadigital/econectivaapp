import 'dart:convert';
import 'evidence_path.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/models/category_model.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/models/connection_type_model.dart';
import 'package:unisinos_usp_app/models/clue_connection_model.dart';
import 'package:unisinos_usp_app/models/node_type_model.dart';
import 'package:unisinos_usp_app/models/node_model.dart';
import 'package:unisinos_usp_app/models/node_link_model.dart';
import 'package:unisinos_usp_app/models/chat_template_model.dart';
import 'package:unisinos_usp_app/models/file_model.dart';
import 'package:unisinos_usp_app/models/user_model.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:unisinos_usp_app/webclients/preferences_webclient.dart';
import 'package:unisinos_usp_app/webclients/sample_webclient.dart';
import 'package:unisinos_usp_app/webclients/sample_detail_webclient.dart';
import 'package:unisinos_usp_app/models/sample_model.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';
import 'package:unisinos_usp_app/webclients/category_webclient.dart';
import 'package:unisinos_usp_app/webclients/clue_connection_webclient.dart';
import 'package:unisinos_usp_app/webclients/connection_type_webclient.dart';
import 'package:unisinos_usp_app/webclients/node_type_webclient.dart';
import 'package:unisinos_usp_app/webclients/node_webclient.dart';
import 'package:unisinos_usp_app/webclients/node_link_webclient.dart';
import 'package:unisinos_usp_app/webclients/chat_template_webclient.dart';
import 'package:unisinos_usp_app/webclients/chat_template_file_webclient.dart';
import 'package:unisinos_usp_app/webclients/file_webclient.dart';
import 'package:unisinos_usp_app/webclients/ai_assistant_webclient.dart';
import 'package:unisinos_usp_app/webclients/living_clue_chat_webclient.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('app clients CRUD, preservation, files and chats on isolated API',
      (tester) async {
    expect({'127.0.0.1', 'localhost'},
        contains(Uri.parse(WebClient.apiBaseUrl).host));
    await app.main();
    await tester.pumpAndSettle();
    final auth = await UserWebclient().login(
        mail: const String.fromEnvironment('E2E_EMAIL'),
        password: const String.fromEnvironment('E2E_PASSWORD'));
    await Get.find<UserController>().savePrefs(auth);
    Get.offAllNamed('/home');
    await tester.pumpAndSettle();
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final cleanup = <Future<void> Function()>[];
    final passed = <String>[];
    try {
      final categories = CategoryWebclient();
      var category = await categories.create(CategoryModel(
          id: 0,
          name: 'UU97 categoria $suffix',
          type: 'experiencia',
          colorHex: '#23AACC',
          metadataTags: 'observacao'));
      cleanup.add(() => categories.delete(category.id));
      category = await categories
          .update(category.copyWith(name: 'UU97 categoria editada $suffix'));
      expect((await categories.fetchById(category.id)).name, category.name);
      passed.add('Categorias: criar, consultar e editar tipo atual da API');
      final clues = LivingClueWebclient();
      var clue = await clues.create(LivingClueModel(
          id: 0,
          name: 'UU97 pista $suffix',
          categoryId: category.id,
          descriptionDelta: jsonEncode([
            {
              'insert': 'Descrição inicial\n',
              'attributes': {'bold': true}
            },
            {
              'insert': {
                'future_embed': {'value': 'preservar'}
              }
            },
            {'insert': '\n'}
          ]),
          metadata: {
            'observacao': 'texto',
            'nested': {
              'values': [1, true, 'x']
            }
          }));
      cleanup.add(() => clues.delete(clue.id));
      expect(clue.hasLocation, isFalse);
      final delta = clue.descriptionDelta;
      final metadata = jsonEncode(clue.metadata);
      clue.name = 'UU97 pista editada $suffix';
      clue = await clues.update(clue);
      expect(clue.descriptionDelta, delta);
      expect(jsonEncode(clue.metadata), metadata);
      clue.latitude = 0;
      clue.longitude = 0;
      clue = await clues.update(clue);
      expect(clue.hasLocation, isTrue);
      expect(
          (await clues.searchByRadius(
                  latitude: 0, longitude: 0, radiusMeters: 100))
              .any((item) => item.id == clue.id),
          isTrue);
      expect(
          (await clues.fetchByBounds(north: 1, south: -1, east: 1, west: -1))
              .any((item) => item.id == clue.id),
          isTrue);
      clue.latitude = null;
      clue.longitude = null;
      clue.removeLocation = true;
      clue = await clues.update(clue);
      expect(clue.hasLocation, isFalse);
      passed.add(
          'Pistas: criar sem localização, editar sem perda de Delta/metadados, coordenada zero, mapa por limites e raio, remover localização');
      Get.toNamed('/living_clues/update', parameters: {'id': '${clue.id}'});
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first,
          'UU97 edição por formulário $suffix');
      await tester.ensureVisible(find.text('Salvar').last);
      await tester.tap(find.text('Salvar').last);
      await tester.pumpAndSettle();
      expect(Get.currentRoute, '/home',
          reason: 'Save must close the form even with a success snackbar');
      clue = await clues.fetchById(clue.id);
      expect(clue.name, 'UU97 edição por formulário $suffix');
      expect(clue.descriptionDelta, delta);
      expect(jsonEncode(clue.metadata), metadata);
      Get.toNamed('/living_clues/create', arguments: {
        'categoryId': category.id,
        'categoryName': category.name,
        'metadataTags': category.metadataTags
      });
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first,
          'UU97 criação por formulário $suffix');
      await tester.ensureVisible(find.text('Salvar').last);
      await tester.tap(find.text('Salvar').last);
      await tester.pumpAndSettle();
      expect(Get.currentRoute, '/home');
      final createdByForm = (await clues.fetch()).singleWhere(
          (item) => item.name == 'UU97 criação por formulário $suffix');
      cleanup.add(() => clues.delete(createdByForm.id));
      expect(createdByForm.hasLocation, isFalse);
      passed.add(
          'Formulários reais: criar e editar pista sem coordenadas, preservar documento/metadados e retornar à tela anterior após salvar');

      final files = FileWebclient();
      final file = await files.upload(FileModel(
          id: 0,
          name: 'uu97.txt',
          extension: 'txt',
          bytes: Uint8List.fromList(utf8.encode('Arquivo sintético UU-97')),
          livingClueId: clue.id));
      cleanup.add(() => files.delete(file.id));
      expect(
          (await files.fetch(livingClueId: clue.id))
              .any((f) => f.id == file.id),
          isTrue);
      final uri = await files.access(file.id);
      final download = await HttpClient().getUrl(uri);
      final response = await download.close();
      expect(response.statusCode, 200);
      expect(await utf8.decodeStream(response), 'Arquivo sintético UU-97');
      passed.add(
          'Anexos: upload multipart, filtro por pista, resolução de acesso autenticado e download íntegro');
      final second = await clues.create(LivingClueModel(
          id: 0, name: 'UU97 destino $suffix', categoryId: category.id));
      cleanup.add(() => clues.delete(second.id));
      final connectionTypes = ConnectionTypeWebclient();
      var type = await connectionTypes
          .create(ConnectionTypeModel(id: 0, name: 'UU97 relação $suffix'));
      cleanup.add(() => connectionTypes.delete(type.id));
      type.name += ' editada';
      type = await connectionTypes.update(type);
      expect((await connectionTypes.fetchById(type.id)).name, type.name);
      final connections = ClueConnectionWebclient();
      var connection = await connections.create(ClueConnectionModel(
          id: 0,
          sourceClueId: clue.id,
          targetClueId: second.id,
          connectionTypeId: type.id));
      cleanup.add(() => connections.delete(connection.id));
      connection.strength = 2;
      connection = await connections.update(connection);
      expect((await connections.fetchById(connection.id)).strength, 2);
      passed.add('Tipos de conexão e conexões: criar, consultar e editar');
      final nodeTypes = NodeTypeWebclient();
      var nt = await nodeTypes.create(
          NodeTypeModel(id: 0, name: 'UU97 tipo $suffix', color: '#23AACC'));
      cleanup.add(() => nodeTypes.delete(nt.id));
      nt.name += ' editado';
      nt = await nodeTypes.update(nt);
      final nodes = NodeWebclient();
      var node = await nodes.create(NodeModel(
          id: 0,
          name: 'UU97 problemática $suffix',
          color: '#23AACC',
          nodeTypeId: nt.id));
      cleanup.add(() => nodes.delete(node.id));
      node.x = 12;
      node.y = 14;
      node = await nodes.update(node);
      expect((await nodes.fetchById(node.id)).x, 12);
      final other = await nodes.create(NodeModel(
          id: 0,
          name: 'UU97 problemática destino $suffix',
          color: '#23AACC',
          nodeTypeId: nt.id));
      cleanup.add(() => nodes.delete(other.id));
      final links = NodeLinkWebclient();
      var link = await links.create(
          NodeLinkModel(id: 0, sourceNodeId: node.id, targetNodeId: other.id));
      cleanup.add(() => links.delete(link.id));
      link = await links.update(link);
      expect((await links.fetchById(link.id)).targetNodeId, other.id);
      expect((await nodes.fetchMap()).nodes.any((n) => n.node.id == node.id),
          isTrue);
      passed.add(
          'Tipos de nó, problemáticas, vínculos e grafo: criação, edição, consulta e posição');
      final templates = ChatTemplateWebclient();
      var template = await templates.create(ChatTemplateModel(
          id: 0,
          name: 'UU97 agente $suffix',
          systemInstruction: 'Responda de modo breve em português.'));
      cleanup.add(() => templates.delete(template.id));
      template.description = 'Descrição editada';
      template = await templates.update(template);
      final sources = ChatTemplateFileWebclient();
      final source = await sources.create(ChatTemplateFileModel(
          chatTemplateId: template.id,
          name: 'Fonte sintética',
          type: 'text',
          content: 'O jardim de teste tem 18 árvores.'));
      cleanup.add(() => sources.delete(source.id!));
      expect(
          (await sources.fetch(chatTemplateId: template.id))
              .any((s) => s.id == source.id),
          isTrue);
      passed.add('Agentes e fontes de contexto: criar, editar e consultar');
      final users = UserWebclient();
      var user = await users.createUser(UserModel(
          id: 0,
          name: 'UU97 conta sintética',
          email: 'uu97-$suffix@example.test',
          profile: 10,
          password: 'Fixture-only-$suffix-Aa!'));
      cleanup.add(() => users.deleteUser(user.id));
      user.name = 'UU97 conta editada';
      user = await users.updateUser(user);
      expect((await users.fetchUserById(user.id)).name, user.name);
      expect((await users.fetchUsers(limit: 1, offset: 1)).length, 1);
      passed.add('Usuários: criar, editar, consultar e paginar');
      final participant = await users.login(
          mail: user.email, password: 'Fixture-only-$suffix-Aa!');
      expect(participant.profile, 10);
      await Get.find<UserController>().savePrefs(participant);
      await expectLater(
          users.fetchUsers(limit: 1), throwsA(contains('permissão')));
      Get.offAllNamed('/home');
      await tester.pumpAndSettle();
      expect(find.text('Usuários'), findsNothing);
      Get.toNamed('/users');
      await tester.pumpAndSettle();
      expect(Get.currentRoute, '/home');
      expect((await users.fetchUserById(user.id)).id, user.id);
      final preferences = PreferencesWebclient();
      await preferences.setEditingEnabled(false);
      expect(await preferences.editingEnabled(), isFalse);
      await expectLater(
          categories.create(CategoryModel(
              id: 0,
              name: 'UU97 bloqueada',
              type: 'teste',
              colorHex: '#23AACC',
              metadataTags: 'observacao')),
          throwsA(contains('Ative criação e edição')));
      Get.toNamed('/profile');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.text('Criação e edição'), findsOneWidget);
      await tester.ensureVisible(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(await preferences.editingEnabled(), isTrue);
      Get.back();
      await tester.pumpAndSettle();
      passed.add(
          'Preferência simples de edição: consulta bloqueia alterações, mensagem orienta Meu perfil e o controle da tela reativa a edição');

      await Get.find<UserController>().savePrefs(auth);
      Get.offAllNamed('/home');
      await tester.pumpAndSettle();
      passed.add(
          'Permissões: participante acessa o próprio perfil, não vê gestão de usuários e é redirecionado ao tentar a rota administrativa');
      // Seed only a disposable account in the explicitly guarded preview database.
      final resetToken = 'uu97-reset-$suffix';
      final seed = await Process.run('docker', [
        'exec',
        'rieonlife-validation-db',
        'sh',
        '-c',
        r'MYSQL_PWD="$MARIADB_ROOT_PASSWORD" mariadb -uroot onlife_validation_preview -e "$1"',
        'usp97-fixture',
        "UPDATE users SET reset_password_token='$resetToken' WHERE id=${user.id} AND email='${user.email}'"
      ]);
      expect(seed.exitCode, 0);
      final recovered = await users.recoverPassword(
          resetToken, 'Recovered-fixture-$suffix-Aa!');
      expect(recovered.id, user.id);
      expect(recovered.token, isNotEmpty);
      expect(
          (await users.login(
                  mail: user.email, password: 'Recovered-fixture-$suffix-Aa!'))
              .id,
          user.id);
      await expectLater(
          users.recoverPassword(resetToken, 'Another-fixture-$suffix-Aa!'),
          throwsA(anything));
      passed.add(
          'Recuperação: campo reset_password_token, troca de senha em conta descartável, novo login e rejeição de token reutilizado');

      final details = await SampleDetailWebclient().select('', 0, {});
      expect(details, isNotEmpty);
      final samples = SampleWebclient();
      var sample = await samples.create(SampleModel(
          id: 0,
          name: 'UU97 amostra',
          sampleString: 'texto',
          sampleUnique: 'uu97-$suffix',
          sampleDetailId: details!.first.id,
          sampleDouble: 1.5,
          sampleDate: DateTime.utc(2026, 10, 22),
          nullableString: 'opcional'));
      cleanup.add(() => samples.delete(sample.id));
      sample.name = 'UU97 amostra editada';
      sample = await samples.update(sample);
      expect((await samples.fetchById(sample.id)).name, sample.name);
      expect(sample.nullableString, 'opcional');
      passed.add(
          'Amostras legadas: seletor correto, criar, editar, consultar, data RFC3339 e campo opcional');

      expect(await AiAssistantWebclient().fetchHistory(), isList);
      expect(await LivingClueChatWebclient().fetchMessages(clue.id), isList);
      expect(await templates.fetchMessages(template.id), isList);
      passed.add('Chats: histórico global, por pista e por agente');
      final globalReply = await AiAssistantWebclient().sendMessage(
          message: 'Teste de compatibilidade: responda brevemente com OK.',
          context: 'Teste sintético do USP App.');
      expect(globalReply.any((m) => !m.isUser && m.content.trim().isNotEmpty),
          isTrue);
      final clueReply = await LivingClueChatWebclient().sendMessage(
          clue.id, 'Responda brevemente confirmando que recebeu a mensagem.');
      expect(
          clueReply.any((m) => !m.isUser && m.text.trim().isNotEmpty), isTrue);
      final agentReply = await templates.sendMessage(
          template.id, 'Quantas árvores tem o jardim da fonte de teste?');
      expect(
          agentReply.any((m) => !m.isUser && m.text.trim().isNotEmpty), isTrue);
      passed.add(
          'Chats reais: enviar e receber resposta de IA global, da pista e do agente com fonte de contexto');
    } finally {
      final cleanupErrors = <String>[];
      for (final action in cleanup.reversed) {
        try {
          await action();
        } catch (error) {
          cleanupErrors.add(error.toString());
        }
      }
      final file = await evidenceFile('crud-tests.json');
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(const JsonEncoder.withIndent('  ')
          .convert({'passed': passed, 'cleanup_errors': cleanupErrors}));
      expect(cleanupErrors, isEmpty);
    }
  }, timeout: const Timeout(Duration(minutes: 8)));
}
