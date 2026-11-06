import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/controllers/ai_assistant/ai_assistant_controller.dart';
import 'package:unisinos_usp_app/controllers/living_clue/living_clue_chat_controller.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:unisinos_usp_app/webclients/chat_template_webclient.dart';
import 'package:unisinos_usp_app/controllers/chat_template/chat_template_chat_controller.dart';
import 'package:unisinos_usp_app/controllers/chat/chat_controller.dart';
import 'usp_plan_test.dart' show capture;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'global assistant and clue chat use current synthetic clue with real provider',
      (tester) async {
    expect(Uri.parse(WebClient.apiBaseUrl).host, '127.0.0.1');
    const id = int.fromEnvironment('E2E_PLANT_ID');
    expect(id, greaterThan(0));
    await (await SharedPreferences.getInstance()).clear();
    await app.main();
    await tester.pump();
    final auth = await UserWebclient().login(
        mail: const String.fromEnvironment('E2E_EMAIL'),
        password: const String.fromEnvironment('E2E_PASSWORD'));
    await Get.find<UserController>().savePrefs(auth);
    Get.offAllNamed('/living_clues/show', parameters: {'id': '$id'});
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    await tester.tap(find.byType(FloatingActionButton).first);
    await tester.pumpAndSettle();
    final assistant = Get.find<AiAssistantController>();
    for (var attempt = 0;
        attempt < 60 && assistant.isLoadingHistory.value;
        attempt++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    final before = assistant.messages.where((m) => !m.isUser).length;
    await tester.enterText(find.byType(TextField).last,
        'USP validação: qual é o nome exato da pista atual? Use o cadastro disponível e informe se os dados são fictícios.');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar').last);
    await tester.pump();
    for (var attempt = 0;
        attempt < 180 && assistant.isSending.value;
        attempt++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(assistant.isSending.value, isFalse);
    expect(assistant.errorMessage.value, isNull);
    expect(
        assistant.messages.where((m) => !m.isUser).length, greaterThan(before));
    expect(assistant.messages.lastWhere((m) => !m.isUser).content,
        contains('USP piloto'));
    await tester.pumpAndSettle();
    await capture(tester, 'global-assistant-context');
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Abrir conversa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir conversa'));
    await tester.pumpAndSettle();
    final chat = Get.find<LivingClueChatController>();
    expect(chat.livingClueId, id);
    final previous = chat.messages.where((m) => !m.isUser).length;
    await tester.enterText(find.byType(TextField).last,
        'USP validação: apresente o seu nome cadastrado, reconhecendo que esta pista é fictícia.');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    for (var attempt = 0; attempt < 180 && chat.isSending.value; attempt++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(chat.isSending.value, isFalse);
    expect(chat.messages.where((m) => !m.isUser).length, greaterThan(previous));
    expect(chat.messages.lastWhere((m) => !m.isUser).text, contains('USP'));
    await tester.pumpAndSettle();
    await capture(tester, 'clue-chat-context');
    final agent = (await ChatTemplateWebclient().fetch(limit: 100))
        .singleWhere((item) => item.name == 'USP agente sintético');
    Get.offNamed('/chat_templates/chat', parameters: {'id': '${agent.id}'});
    await tester.pumpAndSettle();
    final agentChat = Get.find<ChatTemplateChatController>();
    for (var attempt = 0;
        attempt < 60 && agentChat.isLoading.value;
        attempt++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(agentChat.templateId, agent.id);
    final agentBefore =
        agentChat.messages.where((message) => !message.isUser).length;
    await tester.enterText(find.byType(TextField).last,
        'Validação USP: responda brevemente em português, explicando que sem dados não é possível afirmar uma medição real.');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    for (var attempt = 0;
        attempt < 180 && agentChat.isSending.value;
        attempt++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(agentChat.isSending.value, isFalse);
    expect(agentChat.messages.where((message) => !message.isUser).length,
        greaterThan(agentBefore));
    await tester.pumpAndSettle();
    await capture(tester, 'agent-chat-context');
    Get.offNamed('/chat');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    final legacy = Get.find<ChatController>();
    for (var attempt = 0;
        attempt < 60 && legacy.isLoadingHistory.value;
        attempt++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.byType(FloatingActionButton), findsNothing,
        reason:
            'The global assistant must not cover the legacy chat composer.');
    final legacyBefore =
        legacy.messages.where((message) => !message.isUser).length;
    await tester.enterText(find.byType(TextField).last,
        'USP validação de apresentação: explique em uma frase que uma resposta sem dados não comprova medição.');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await capture(tester, 'legacy-chat-composer');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    for (var attempt = 0; attempt < 180 && legacy.isSending.value; attempt++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(legacy.isSending.value, isFalse);
    expect(legacy.messages.where((message) => !message.isUser).length,
        greaterThan(legacyBefore));
    expect(legacy.messages.lastWhere((message) => !message.isUser).text,
        isNot(contains('Não foi possível enviar sua mensagem')));
    await tester.pumpAndSettle();
    await capture(tester, 'legacy-chat-response');
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
