import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/widgets/cdig_creation_notice.dart';
import 'package:unisinos_usp_app/widgets/clue_content.dart';

void main() {
  testWidgets('disabled or unavailable integration leaves creation available',
      (tester) async {
    for (final load in <Future<Uri?> Function()>[
      () async => null,
      () => Future<Uri?>.error(Exception('source unavailable')),
    ]) {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Column(children: [
        CdigCreationNotice(key: UniqueKey(), load: load),
        const TextField(
            decoration: InputDecoration(labelText: 'Nome da pista')),
      ]))));
      await tester.pump();
      expect(find.text('Acessar Cidadania Digital'), findsNothing);
      await tester.enterText(find.byType(TextField), 'Minha pista local');
      expect(find.text('Minha pista local'), findsOneWidget);
    }
  });

  testWidgets('configured integration shows the destination notice',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CdigCreationNotice(
                load: () async => Uri.parse('https://cdig.example')))));
    await tester.pump();
    expect(find.text('Acessar Cidadania Digital'), findsOneWidget);
    expect(
        find.textContaining('As pistas criadas aqui ficam nesta plataforma.'),
        findsOneWidget);
  });

  testWidgets(
      'source metadata is readable without internal synchronization JSON',
      (tester) async {
    final clue =
        LivingClueModel(id: 1, name: 'Referência', categoryId: 1, metadata: {
      'cdig': {
        'author': 'Ana',
        'rights': 'CC BY',
        'state': 'unavailable',
        'environment': 'internal-staging-key',
        'url': 'https://cdig.example/reference',
        'subject': {'Name': 'Educação'},
      }
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(child: ClueContent(clue: clue)))));
    expect(find.text('Autoria: Ana'), findsOneWidget);
    expect(find.text('Direitos: CC BY'), findsOneWidget);
    expect(find.text('Tema: Educação'), findsOneWidget);
    expect(find.textContaining('deixou de estar disponível'), findsOneWidget);
    expect(find.textContaining('internal-staging-key'), findsNothing);
    expect(find.textContaining('resource-99'), findsNothing);
    expect(find.text('Características cadastradas'), findsNothing);
    expect(find.text('Consultar referência de origem'), findsOneWidget);
  });
}
