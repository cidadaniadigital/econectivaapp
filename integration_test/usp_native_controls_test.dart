import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';
import 'package:unisinos_usp_app/webclients/preferences_webclient.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'usp_plan_test.dart' show capture;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'real orientation, native keyboard and Android Back preserve the clue',
      (tester) async {
    expect(Uri.parse(WebClient.apiBaseUrl).host, '127.0.0.1');
    const clueId = int.fromEnvironment('E2E_PLANT_ID');
    const collectionId = int.fromEnvironment('E2E_COLLECTION_ID');
    expect(clueId, greaterThan(0));
    expect(collectionId, greaterThan(0));
    final cache = await getTemporaryDirectory();
    for (final stage in [1, 2]) {
      for (final suffix in ['', '-ack']) {
        final marker = File('${cache.path}/usp-native-back-$stage$suffix');
        if (marker.existsSync()) marker.deleteSync();
      }
    }
    Future<void> rotate(bool landscape) async {
      await SystemChrome.setPreferredOrientations([
        landscape
            ? DeviceOrientation.landscapeLeft
            : DeviceOrientation.portraitUp
      ]);
      for (var attempt = 0; attempt < 20; attempt++) {
        await tester.pump(const Duration(milliseconds: 500));
        final size = tester.view.physicalSize;
        if ((size.width > size.height) == landscape) break;
      }
      await tester.pumpAndSettle();
      final size = tester.view.physicalSize;
      expect(size.width > size.height, landscape,
          reason: 'The actual Android view must rotate.');
    }

    Future<void> nativeBack(int stage) async {
      final ack = File('${cache.path}/usp-native-back-$stage-ack');
      await File('${cache.path}/usp-native-back-$stage').writeAsString('ready');
      for (var attempt = 0; attempt < 60 && !ack.existsSync(); attempt++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(ack.existsSync(), isTrue,
          reason: 'Native instrumentation must deliver Android Back.');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    try {
      await (await SharedPreferences.getInstance()).clear();
      await app.main();
      await tester.pump();
      final auth = await UserWebclient().login(
          mail: const String.fromEnvironment('E2E_EMAIL'),
          password: const String.fromEnvironment('E2E_PASSWORD'));
      await Get.find<UserController>().savePrefs(auth);
      await PreferencesWebclient().setEditingEnabled(true);
      final original = await LivingClueWebclient().fetchById(clueId);
      Get.offAllNamed('/living_clues/show', parameters: {'id': '$clueId'});
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await rotate(false);
      await capture(tester, 'detail-portrait');
      await rotate(true);
      expect(tester.takeException(), isNull);
      await capture(tester, 'detail-landscape');
      await rotate(false);
      await tester.tap(find.byTooltip('Editar pista'));
      await tester.pumpAndSettle();
      final name = find.byType(TextFormField).first;
      await tester.tap(name);
      await tester.enterText(name, 'Alteração descartada pelo botão Android');
      for (var attempt = 0;
          attempt < 20 && tester.view.viewInsets.bottom == 0;
          attempt++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(tester.view.viewInsets.bottom, greaterThan(0),
          reason: 'The actual native keyboard must be visible.');
      await nativeBack(1);
      expect(tester.view.viewInsets.bottom, 0);
      expect(Get.currentRoute, startsWith('/living_clues/update'));
      await nativeBack(2);
      expect(Get.currentRoute, startsWith('/living_clues/show'));
      expect(
          (await LivingClueWebclient().fetchById(clueId)).name, original.name);
      await capture(tester, 'back-unsaved-preserved');
      Get.toNamed('/collections/show', parameters: {'id': '$collectionId'});
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await capture(tester, 'collection-portrait');
      await rotate(true);
      expect(tester.takeException(), isNull);
      await capture(tester, 'collection-landscape');
      await rotate(false);
    } finally {
      await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp]);
      for (final stage in [1, 2]) {
        for (final suffix in ['', '-ack']) {
          final marker = File('${cache.path}/usp-native-back-$stage$suffix');
          if (marker.existsSync()) marker.deleteSync();
        }
      }
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
