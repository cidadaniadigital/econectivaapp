import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/widgets/clue_identity.dart';

void main() {
  for (final width in [320.0, 390.0, 1440.0]) {
    testWidgets('generic clue identity fits $width pixels', (tester) async {
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final clue = LivingClueModel(
          id: 1,
          name: 'Pesquisador de demonstração com nome comprido',
          categoryId: 1,
          description:
              'Descrição declarada da entidade, sem atribuição de características de planta.',
          metadata: {'dados_ficticios': true});
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: ClueIdentity(clue: clue, canEdit: true))))));
      await tester.pumpAndSettle();
      expect(find.text('Abrir conversa'), findsOneWidget);
      expect(find.text('Conectar a outra pista'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
