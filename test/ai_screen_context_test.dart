import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/ai_assistant_screen_context.dart';
import 'package:unisinos_usp_app/services/ai_assistant_context_builder.dart';
import 'package:unisinos_usp_app/services/ai_assistant_context_service.dart';

AiAssistantScreenContext context(String route, String id) =>
    AiAssistantScreenContext(
        screenName: 'Detalhe',
        route: route,
        stage: 'consulta',
        goal: 'Consultar',
        filledFields: {'id': id});
void main() {
  test(
      'structured context uses supported clue reference without treating other IDs as clues',
      () {
    expect(
        AiAssistantContextBuilder.toApi(
            context('/living_clues/show?id=8', '8'))['references'],
        {'living_clue_id': 8});
    expect(
        AiAssistantContextBuilder.toApi(
            context('/categories/update?id=8', '8'))['references'],
        isEmpty);
    expect(
        AiAssistantContextBuilder.toApi(
            context('/living_clues/show?id=-1', '-1'))['references'],
        isEmpty);
  });
  testWidgets('changing clue ID cannot reuse previous loaded clue context',
      (tester) async {
    final service = AiAssistantContextService();
    await tester.pumpWidget(
        GetMaterialApp(initialRoute: '/living_clues/show?id=8', getPages: [
      GetPage(name: '/living_clues/show', page: () => const Scaffold()),
    ]));
    await tester.pumpAndSettle();
    service.registerProvider('/living_clues/show?id=8',
        () => context('/living_clues/show?id=8', '8'));
    service.setCurrentRoute('/living_clues/show?id=8');
    expect(service.resolveCurrentContext().filledFields['id'], '8');
    Get.offAllNamed('/living_clues/show', parameters: {'id': '9'});
    await tester.pumpAndSettle();
    final current = service.resolveCurrentContext();
    expect(current.filledFields['id'], isNot('8'));
    expect(AiAssistantContextBuilder.toApi(current)['references'],
        {'living_clue_id': 9});
    Get.reset();
  });
}
