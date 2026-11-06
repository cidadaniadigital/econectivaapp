import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/models/chat_template_model.dart';
import 'package:unisinos_usp_app/screens/chat_template/chat_template_form.dart';
import 'package:unisinos_usp_app/themes/app_theme.dart';

void main() {
  testWidgets('agent instructions are required before submitting to the API',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final saved = <ChatTemplateFormValue>[];
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
            body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ChatTemplateForm(
            initialValue: ChatTemplateModel(id: 1, name: 'Agente sintético'),
            showSources: false,
            submitLabel: 'Salvar',
            isLoading: false,
            onSubmit: (value) async {
              saved.add(value);
            },
          ),
        ))));
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(saved, isEmpty);
    expect(find.text('Obrigatório'), findsOneWidget);
    final instruction = find.byWidgetPredicate((w) =>
        w is TextField && w.decoration?.hintText == 'System instruction');
    await tester.ensureVisible(instruction);
    await tester.enterText(instruction, 'Reconheça os limites dos dados.');
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(saved, hasLength(1));
    expect(saved.single.systemInstruction, 'Reconheça os limites dos dados.');
    expect(tester.takeException(), isNull);
  });
}
