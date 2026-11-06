import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/models/file_model.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/webclients/category_webclient.dart';
import 'package:unisinos_usp_app/webclients/file_webclient.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';
import 'package:unisinos_usp_app/webclients/preferences_webclient.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'usp_plan_test.dart' show capture;
import 'evidence_path.dart' show publishEvidence;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('attachment opens in a real external Android viewer',
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
        .firstWhere((c) => c.name == 'Laboratório de integrações');
    final clues = LivingClueWebclient();
    final files = FileWebclient();
    final cache = await getTemporaryDirectory();
    final ready = File('${cache.path}/usp-attachment-open-ready');
    final result = File('${cache.path}/usp-attachment-open-result');
    for (final marker in [ready, result]) {
      if (marker.existsSync()) marker.deleteSync();
    }
    final clue = await clues.create(LivingClueModel(
        id: 0,
        name:
            'USP abertura de anexo descartável ${DateTime.now().microsecondsSinceEpoch}',
        categoryId: category.id));
    try {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawColor(const Color(0xFF5D2FB5), BlendMode.src);
      final picture = recorder.endRecording();
      final image = await picture.toImage(320, 180);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final data = bytes!.buffer.asUint8List();
      image.dispose();
      picture.dispose();
      final uploaded = await files.upload(FileModel(
          id: 0,
          name: 'usp-native-open.png',
          extension: 'png',
          bytes: data,
          size: data.length,
          livingClueId: clue.id));
      final target = await files.access(uploaded.id);
      expect(target.host, '127.0.0.1');
      expect(target.query, isEmpty,
          reason: 'Only token-free local fixture URLs may be captured.');
      Get.offAllNamed('/living_clues/show', parameters: {'id': '${clue.id}'});
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await tester.ensureVisible(find.text('usp-native-open.png'));
      await tester.pumpAndSettle();
      await capture(tester, 'attachment-before-external-open');
      await ready.writeAsString('ready');
      await tester.tap(find.text('usp-native-open.png'));
      await tester.pump();
      for (var attempt = 0; attempt < 120 && !result.existsSync(); attempt++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(result.existsSync(), isTrue,
          reason: 'Native viewer driver must report its result.');
      final report =
          jsonDecode(await result.readAsString()) as Map<String, dynamic>;
      await publishEvidence('attachment-open-checks.json', report);
      expect(report['passed'], true, reason: report['reason']?.toString());
      expect(report['matching_pixels'], greaterThan(5000));
      expect(report['returned_to_app_using_back'], true);
      await tester.pumpAndSettle();
      expect(find.text('usp-native-open.png'), findsOneWidget);
      await capture(tester, 'attachment-after-external-return');
    } finally {
      for (final file in await files.fetch(livingClueId: clue.id)) {
        await files.delete(file.id);
      }
      await clues.delete(clue.id);
      expect(await files.fetch(livingClueId: clue.id), isEmpty);
      await publishEvidence('attachment-open-cleanup.json', {
        'removed_clue_id': clue.id,
        'remaining_files': 0,
        'scope': 'Only own disposable clue and its attachment'
      });
      for (final marker in [ready, result]) {
        if (marker.existsSync()) marker.deleteSync();
      }
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
