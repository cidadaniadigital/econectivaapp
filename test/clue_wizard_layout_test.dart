import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisinos_usp_app/screens/living_clue/living_clue_pre_create_screen.dart';
import 'package:unisinos_usp_app/services/ai_assistant_context_service.dart';
import 'package:unisinos_usp_app/themes/app_theme.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets(
          'selected type heading wraps at $width with text scale $scale',
          (tester) async {
        SharedPreferences.setMockInitialValues({});
        Get.testMode = true;
        Get.put(AiAssistantContextService());
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          Get.reset();
          Get.testMode = false;
        });
        await tester.pumpWidget(GetMaterialApp(
            theme: AppTheme.theme,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            getPages: [
              GetPage(name: '/base', page: () => const Scaffold()),
              GetPage(
                  name: '/category',
                  page: () => const LivingCluePreCreateScreen())
            ],
            initialRoute: '/base'));
        await tester.pumpAndSettle();
        Get.toNamed('/category', arguments: {'type': 'Pista Online'});
        await tester.pumpAndSettle();
        final title = find.text('Selecione a categoria base de Pista Online');
        expect(title, findsOneWidget);
        final bounds = tester.getRect(title);
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(width - 16));
        if (width == 320) expect(bounds.height, greaterThan(25));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
