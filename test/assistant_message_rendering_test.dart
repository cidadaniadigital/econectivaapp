import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/ai_assistant/ai_assistant_controller.dart';
import 'package:unisinos_usp_app/models/ai_assistant_message_model.dart';
import 'package:unisinos_usp_app/services/ai_assistant_context_service.dart';
import 'package:unisinos_usp_app/widgets/ai_assistant_panel.dart';

void main() {
  tearDown(() => Get.reset());
  testWidgets('global answer renders Markdown and opens known clue reference',
      (tester) async {
    Get.put(AiAssistantContextService());
    final controller = Get.put(AiAssistantController());
    controller.hasLoadedHistory.value = true;
    controller.messages.add(AiAssistantMessageModel(
        role: 'assistant',
        content: '**Nome:** [Planta fictícia](#/space/research/55)',
        createdAt: DateTime(2026, 10, 27)));
    await tester.pumpWidget(GetMaterialApp(
      home: const Scaffold(body: AiAssistantPanel()),
      getPages: [
        GetPage(
            name: '/living_clues/show',
            page: () => Scaffold(body: Text('Pista ${Get.parameters['id']}')))
      ],
    ));
    await tester.pumpAndSettle();
    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(find.text('**Nome:** [Planta fictícia](#/space/research/55)'),
        findsNothing);
    await tester
        .tap(find.textContaining('Planta fictícia', findRichText: true));
    await tester.pumpAndSettle();
    expect(find.text('Pista 55'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('a reference to the visible clue dismisses the assistant sheet',
      (tester) async {
    Get.put(AiAssistantContextService());
    final controller = Get.put(AiAssistantController());
    controller.hasLoadedHistory.value = true;
    controller.messages.add(AiAssistantMessageModel(
        role: 'assistant',
        content: '[Planta fictícia](#/space/research/55)',
        createdAt: DateTime(2026, 10, 27)));
    await tester.pumpWidget(GetMaterialApp(
      initialRoute: '/living_clues/show?id=55',
      getPages: [
        GetPage(
            name: '/living_clues/show',
            page: () => Builder(
                builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => const AiAssistantPanel()),
                        child: const Text('Abrir assistente')))))
      ],
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir assistente'));
    await tester.pumpAndSettle();
    expect(find.byType(AiAssistantPanel), findsOneWidget);
    await tester
        .tap(find.textContaining('Planta fictícia', findRichText: true));
    await tester.pumpAndSettle();
    expect(find.byType(AiAssistantPanel), findsNothing);
    expect(find.text('Abrir assistente'), findsOneWidget);
  });
}
