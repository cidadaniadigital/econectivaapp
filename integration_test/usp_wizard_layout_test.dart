import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgets_spo/widgets_spo.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:unisinos_usp_app/webclients/preferences_webclient.dart';
import 'package:unisinos_usp_app/webclients/category_webclient.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'usp_plan_test.dart' show capture;
import 'evidence_path.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'type selection reaches a wrapping category heading and valid creation form',
      (tester) async {
    expect(Uri.parse(WebClient.apiBaseUrl).host, '127.0.0.1');
    await (await SharedPreferences.getInstance()).clear();
    await app.main();
    await tester.pump();
    final auth = await UserWebclient().login(
        mail: const String.fromEnvironment('E2E_EMAIL'),
        password: const String.fromEnvironment('E2E_PASSWORD'));
    await Get.find<UserController>().savePrefs(auth);
    await PreferencesWebclient().setEditingEnabled(true);
    final category = (await CategoryWebclient().fetch())
        .firstWhere((c) => c.type == 'Pista Online');
    Future<void> settle() =>
        tester.pumpAndSettle(const Duration(milliseconds: 500));
    Get.offAllNamed('/living_clues/type_select');
    await settle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await settle();
    await tester.tap(find.text('Pista Online').last);
    await settle();
    await tester.tap(find.text('Continuar').last);
    await settle();
    expect(Uri.parse(Get.currentRoute).path, '/living_clues/pre_create');
    final title = find.text('Selecione a categoria base de Pista Online');
    expect(title, findsOneWidget);
    expect(tester.getRect(title).right,
        lessThanOrEqualTo(MediaQuery.sizeOf(tester.element(title)).width - 16));
    expect(tester.takeException(), isNull);
    await capture(tester, 'wizard-category-typed');
    final categoryField = find.byWidgetPredicate(
        (w) => w is InputSelectApi && w.label == 'Categoria');
    await tester.tap(categoryField);
    await settle();
    await tester.tap(find.text(category.name).last);
    await settle();
    await tester.tap(find.text('Continuar').last);
    await settle();
    expect(Uri.parse(Get.currentRoute).path, '/living_clues/create');
    expect(find.text('Nova pista viva'), findsOneWidget);
    expect(Get.arguments['categoryId'], category.id);
    expect(tester.takeException(), isNull);
    await capture(tester, 'wizard-valid-category-form');
    await publishEvidence('wizard-layout-checks.json', {
      'status': 'aprovado no escopo descrito',
      'type_selected_through_ui': 'Pista Online',
      'category_filter': true,
      'heading_within_viewport': true,
      'actual_category_arguments': true,
      'new_clues_created': 0
    });
  });
}
