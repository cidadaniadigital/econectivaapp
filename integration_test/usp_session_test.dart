import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgets_spo/services/auth_provider.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/services/auth_user.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'usp_plan_test.dart' show capture;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'session survives process restart and handles failed/expired login',
      (tester) async {
    expect(Uri.parse(WebClient.apiBaseUrl).host, '127.0.0.1');
    const phase = String.fromEnvironment('E2E_SESSION_PHASE');
    expect(['save', 'restore'], contains(phase));
    if (phase == 'save') {
      await (await SharedPreferences.getInstance()).clear();
    }
    await app.main();
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    final users = Get.find<UserController>();
    Future<void> login({bool wrong = false}) async {
      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(2));
      await tester.enterText(
          fields.at(0), const String.fromEnvironment('E2E_EMAIL'));
      await tester.enterText(
          fields.at(1),
          wrong
              ? 'Incorrect-synthetic-password-Aa!'
              : const String.fromEnvironment('E2E_PASSWORD'));
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await tester.ensureVisible(find.text('Entrar').last);
      await tester.tap(find.text('Entrar').last);
      for (var attempt = 0; attempt < 20; attempt++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (wrong
            ? find
                .textContaining('Falha ao realizar login')
                .evaluate()
                .isNotEmpty
            : users.isLoggedIn) break;
      }
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    if (phase == 'save') {
      await login();
      expect(users.isLoggedIn, isTrue);
      expect(Get.currentRoute, '/home');
      await (await SharedPreferences.getInstance())
          .setInt('usp-session-validation-pid', pid);
      await capture(tester, 'session-before-process-restart');
      return;
    }
    expect(users.isLoggedIn, isTrue,
        reason:
            'This is a fresh Flutter/Android process without clearing prefs.');
    expect(Get.currentRoute, '/home');
    expect(
        (await SharedPreferences.getInstance())
            .getInt('usp-session-validation-pid'),
        isNot(pid));
    await capture(tester, 'session-after-process-restart');
    await AuthProvider.instance.logout();
    await tester.pumpAndSettle();
    Get.offAllNamed('/living_clues/show?id=55');
    await tester.pumpAndSettle();
    expect(Get.parameters['return'], '/living_clues/show?id=55');
    await login(wrong: true);
    expect(find.textContaining('Falha ao realizar login'), findsWidgets);
    expect(users.isLoggedIn, isFalse);
    expect(Get.parameters['return'], '/living_clues/show?id=55');
    // Leave credentials out of the screenshot, including password length.
    await tester.enterText(find.byType(TextFormField).at(1), '');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await capture(tester, 'login-failure-return');
    await login();
    expect(Get.currentRoute, startsWith('/living_clues/show'));
    expect(Get.parameters['id'], '55');
    final previous = users.user.value!;
    const expired = String.fromEnvironment('E2E_EXPIRED_TOKEN');
    expect(expired, isNotEmpty);
    await users.savePrefs(AuthUser(
        id: previous.id,
        name: previous.name,
        email: previous.email,
        token: expired,
        profile: previous.profile));
    Get.offAllNamed('/home');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    Get.offAllNamed('/living_clues/show?id=55');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(users.isLoggedIn, isFalse);
    expect(Get.currentRoute, startsWith('/login'));
    expect(Get.parameters['return'], '/living_clues/show?id=55');
    await capture(tester, 'session-expired-return');
    await login();
    expect(Get.parameters['id'], '55');
    await AuthProvider.instance.logout();
    await tester.pumpAndSettle();
    Get.offAllNamed('/login',
        parameters: {'return': 'https://example.org/unsafe'});
    await tester.pumpAndSettle();
    await login();
    expect(Get.currentRoute, '/home');
    await capture(tester, 'external-return-rejected');
    Get.offAllNamed('/living_clues/show?id=127');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(
        find.text('Falha ao carregar pista. Tentar novamente'), findsOneWidget);
    expect(Get.currentRoute, startsWith('/living_clues/show'));
    await capture(tester, 'deleted-clue');
    expect(tester.takeException(), isNull);
  });
}
