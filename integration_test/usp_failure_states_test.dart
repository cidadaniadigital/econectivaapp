import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/controllers/ai_assistant/ai_assistant_controller.dart';
import 'package:unisinos_usp_app/controllers/living_clue/living_clue_chat_controller.dart';
import 'package:unisinos_usp_app/controllers/chat_template/chat_template_chat_controller.dart';
import 'package:unisinos_usp_app/controllers/chat/chat_controller.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';
import 'package:unisinos_usp_app/webclients/chat_template_webclient.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:unisinos_usp_app/widgets/clue_cover.dart';
import 'usp_plan_test.dart' show capture;
import 'evidence_path.dart' show publishEvidence;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'HTTP failure states preserve context and recover without invented replies',
      (tester) async {
    final base = Uri.parse(WebClient.apiBaseUrl);
    expect(base.host, '127.0.0.1');
    expect(base.port, 8084);
    const key = String.fromEnvironment('E2E_FAULT_KEY');
    expect(key.length, greaterThanOrEqualTo(24));
    Future<Map<String, dynamic>> fault(String value) async {
      final response = await http.post(
          Uri.parse('http://127.0.0.1:8084/__fault/control'),
          headers: {'Content-Type': 'application/json', 'X-USP-Fault-Key': key},
          body: jsonEncode({'fault': value}));
      expect(response.statusCode, 200);
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    Future<void> settle() async =>
        tester.pumpAndSettle(const Duration(milliseconds: 500));
    Future<void> send(String value, IconData icon) async {
      await tester.enterText(find.byType(TextField).last, value);
      FocusManager.instance.primaryFocus?.unfocus();
      await settle();
      await tester.tap(find.byIcon(icon).last);
      await tester.pump();
      for (var i = 0;
          i < 60 &&
              find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
          i++) await tester.pump(const Duration(milliseconds: 500));
      await settle();
    }

    await fault('none');
    await (await SharedPreferences.getInstance()).clear();
    await app.main();
    await tester.pump();
    final auth = await UserWebclient().login(
        mail: const String.fromEnvironment('E2E_EMAIL'),
        password: const String.fromEnvironment('E2E_PASSWORD'));
    await Get.find<UserController>().savePrefs(auth);
    const id = int.fromEnvironment('E2E_PLANT_ID');
    expect(id, greaterThan(0));
    final clue = await LivingClueWebclient().fetchById(id);
    final agent = (await ChatTemplateWebclient().fetch(limit: 100))
        .singleWhere((a) => a.name == 'USP agente sintético');
    final before = await fault('catalog');
    try {
      Get.offAllNamed('/catalog');
      await settle();
      for (var i = 0;
          i < 40 &&
              find
                  .textContaining('Não foi possível carregar o catálogo.')
                  .evaluate()
                  .isEmpty;
          i++) await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('Não foi possível carregar o catálogo.'),
          findsOneWidget);
      await capture(tester, 'catalog-http-failure');
      await fault('none');
      await tester.tap(find.textContaining('Tentar novamente'));
      await settle();
      for (var i = 0; i < 40 && find.byType(ClueCover).evaluate().isEmpty; i++)
        await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ClueCover), findsWidgets);
      expect(find.textContaining('Não foi possível carregar o catálogo.'),
          findsNothing);
      await capture(tester, 'catalog-http-recovered');
      await fault('layers');
      Get.offAllNamed('/living_clues/show', parameters: {'id': '$id'});
      await settle();
      expect(find.text('Bioma'), findsOneWidget);
      expect(find.text('Densidade populacional'), findsOneWidget);
      expect(find.textContaining('Fonte sintética'), findsWidgets);
      expect(find.textContaining('Consultar fonte no catálogo'), findsNothing);
      await tester.ensureVisible(find.text('Contexto ambiental'));
      await settle();
      await capture(tester, 'source-catalog-http-failure');
      await fault('chat');
      await tester.tap(find.byType(FloatingActionButton).first);
      await settle();
      final assistant = Get.find<AiAssistantController>();
      for (var i = 0; i < 40 && assistant.isLoadingHistory.value; i++)
        await tester.pump(const Duration(milliseconds: 500));
      final assistantBefore = assistant.messages.where((m) => !m.isUser).length;
      await tester.enterText(find.byType(TextField).last,
          'Falha sintética de transporte; não persistir esta mensagem.');
      FocusManager.instance.primaryFocus?.unfocus();
      await settle();
      await tester.tap(find.text('Enviar').last);
      await tester.pump();
      for (var i = 0; i < 60 && assistant.isSending.value; i++)
        await tester.pump(const Duration(milliseconds: 500));
      await settle();
      expect(assistant.errorMessage.value,
          'Não foi possível enviar a mensagem agora.');
      expect(
          assistant.messages.where((m) => !m.isUser).length, assistantBefore);
      expect(assistant.isSending.value, false);
      await capture(tester, 'global-chat-http-failure');
      await tester.tap(find.byIcon(Icons.close).first);
      await settle();
      Get.offAllNamed('/living_clues/$id/chat', arguments: {'model': clue});
      await settle();
      final chat = Get.find<LivingClueChatController>();
      for (var i = 0; i < 40 && chat.isLoading.value; i++)
        await tester.pump(const Duration(milliseconds: 500));
      final chatBefore = chat.messages.length;
      await send('Falha sintética de transporte da pista.', Icons.send_rounded);
      for (var i = 0; i < 60 && chat.isSending.value; i++)
        await tester.pump(const Duration(milliseconds: 500));
      await settle();
      expect(chat.messages.length, chatBefore);
      expect(find.textContaining('Falha ao enviar mensagem.'), findsWidgets);
      expect(chat.isSending.value, false);
      await capture(tester, 'clue-chat-http-failure');
      Get.offAllNamed('/chat_templates/chat',
          parameters: {'id': '${agent.id}'});
      await settle();
      final agentChat = Get.find<ChatTemplateChatController>();
      for (var i = 0; i < 40 && agentChat.isLoading.value; i++)
        await tester.pump(const Duration(milliseconds: 500));
      final agentBefore = agentChat.messages.length;
      await send(
          'Falha sintética de transporte do agente.', Icons.send_rounded);
      for (var i = 0; i < 60 && agentChat.isSending.value; i++)
        await tester.pump(const Duration(milliseconds: 500));
      await settle();
      expect(agentChat.messages.length, agentBefore);
      expect(agentChat.isSending.value, false);
      expect(find.textContaining('Falha ao enviar mensagem.'), findsWidgets);
      await capture(tester, 'agent-chat-http-failure');
      Get.offAllNamed('/chat');
      await settle();
      final legacy = Get.find<ChatController>();
      for (var i = 0; i < 40 && legacy.isLoadingHistory.value; i++)
        await tester.pump(const Duration(milliseconds: 500));
      await send(
          'Falha sintética de transporte do chat legado.', Icons.send_rounded);
      for (var i = 0; i < 60 && legacy.isSending.value; i++)
        await tester.pump(const Duration(milliseconds: 500));
      await settle();
      expect(
          find.text('Não foi possível enviar sua mensagem. Tente novamente.'),
          findsOneWidget);
      expect(legacy.isSending.value, false);
      await capture(tester, 'legacy-chat-http-failure');
      final after = await fault('none');
      final old = before['injected'] as Map<String, dynamic>;
      final current = after['injected'] as Map<String, dynamic>;
      final deltas = {
        for (final mode in ['catalog', 'layers', 'chat'])
          mode: (current[mode] as int? ?? 0) - (old[mode] as int? ?? 0)
      };
      expect(deltas['catalog'], greaterThanOrEqualTo(1));
      expect(deltas['layers'], greaterThanOrEqualTo(1));
      expect(deltas['chat'], 4);
      await publishEvidence('http-failure-checks.json', {
        'status': 'aprovado',
        'scope':
            'controlled loopback HTTP503 injection; not a live provider outage',
        'catalog_retry_recovers': true,
        'snapshot_sources_preserved_without_catalog': true,
        'four_chat_interfaces_handle_error': true,
        'no_invented_provider_reply': true,
        'injected_request_deltas': deltas,
        'faults_restored': 'none',
        'failed_chat_posts_forwarded_to_api': false
      });
    } finally {
      await fault('none');
    }
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 4)));
}
