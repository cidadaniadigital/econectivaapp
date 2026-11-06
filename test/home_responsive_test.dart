import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/screens/home_screen.dart';
import 'package:unisinos_usp_app/services/ai_assistant_context_service.dart';
import 'package:unisinos_usp_app/services/user_auth_service.dart';
import 'package:unisinos_usp_app/themes/app_theme.dart';
import 'package:widgets_spo/services/auth_provider.dart';
import 'package:widgets_spo/utils.dart';

void main() {
  for (final width in [320.0, 390.0, 1280.0]) {
    testWidgets('home fits viewport $width without hiding logout',
        (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'user': jsonEncode({
          'id': 1,
          'name': 'Nome de teste longo',
          'email': 'test@example.test',
          'token': 'synthetic',
          'profile': 40
        })
      });
      PackageInfo.setMockInitialValues(
          appName: 'test',
          packageName: 'test',
          version: '1',
          buildNumber: '1',
          buildSignature: '');
      await Util.initPrefs();
      AuthProvider.register(UserAuthService());
      Get.put(UserController());
      Get.put(AiAssistantContextService());
      await tester.pumpWidget(
          GetMaterialApp(theme: AppTheme.theme, home: HomeScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final logout = width < 600 ? find.byTooltip('Sair') : find.text('Sair');
      expect(logout, findsOneWidget);
      expect(tester.getRect(logout).right, lessThanOrEqualTo(width));
      await tester.pumpWidget(const SizedBox.shrink());
      Get.reset();
    });
  }
}
