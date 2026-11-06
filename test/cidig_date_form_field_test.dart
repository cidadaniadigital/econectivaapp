import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_spo/widgets/input_form_date.dart'
    show DateTimeController;
import 'package:unisinos_usp_app/themes/app_theme.dart';
import 'package:unisinos_usp_app/widgets/cidig_date_form_field.dart';

Widget host(Widget child) => MaterialApp(
    theme: AppTheme.theme,
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child)));

void main() {
  testWidgets('canceling the calendar preserves the selected date',
      (tester) async {
    final controller = DateTimeController(initialValue: DateTime(2026, 3, 12));
    addTearDown(controller.dispose);
    await tester.pumpWidget(
        host(CidigDateFormField(controller: controller, label: 'Data')));
    await tester.tap(find.text('12/03/2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(controller.value, DateTime(2026, 3, 12));
    expect(find.text('12/03/2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting a new day updates the existing form controller',
      (tester) async {
    final controller = DateTimeController(initialValue: DateTime(2026, 3, 12));
    addTearDown(controller.dispose);
    await tester.pumpWidget(
        host(CidigDateFormField(controller: controller, label: 'Data')));
    await tester.tap(find.text('12/03/2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.tap(find.text('Selecionar'));
    await tester.pumpAndSettle();
    expect(controller.value, DateTime(2026, 3, 15));
    expect(find.text('15/03/2026'), findsOneWidget);
  });

  testWidgets(
      'required validation and programmatic controller updates work at320',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = DateTimeController();
    addTearDown(controller.dispose);
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(host(Form(
        key: form,
        child: CidigDateFormField(
            controller: controller,
            label: 'Data',
            validator: (v) => v == null ? 'Use uma data válida' : null))));
    expect(form.currentState!.validate(), false);
    await tester.pump();
    expect(find.text('Use uma data válida'), findsOneWidget);
    controller.value = DateTime(2026, 3, 12);
    await tester.pump();
    expect(form.currentState!.validate(), true);
    await tester.pump();
    expect(find.text('12/03/2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
