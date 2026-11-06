import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/webclients/file_webclient.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:unisinos_usp_app/widgets/clue_cover.dart';
import 'usp_plan_test.dart' show capture;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('private S3 cover renders after the original signed URL expires',
      (tester) async {
    expect(Uri.parse(WebClient.apiBaseUrl).host, '127.0.0.1');
    const clueId = int.fromEnvironment('E2E_COVER_CLUE_ID');
    const fileId = int.fromEnvironment('E2E_COVER_FILE_ID');
    const expiredEpoch = int.fromEnvironment('E2E_COVER_EXPIRES_EPOCH');
    expect(clueId, greaterThan(0));
    expect(fileId, greaterThan(0));
    expect(expiredEpoch, greaterThan(0));
    // Real time, not an accelerated test clock: the server-issued five-minute
    // signature must have expired before a clean process resolves the image.
    await tester.runAsync(() async {
      final remaining = DateTime.fromMillisecondsSinceEpoch(
              (expiredEpoch + 3) * 1000,
              isUtc: true)
          .difference(DateTime.now().toUtc());
      if (!remaining.isNegative) await Future<void>.delayed(remaining);
    });
    expect(
        DateTime.now().millisecondsSinceEpoch ~/ 1000 > expiredEpoch, isTrue);
    await (await SharedPreferences.getInstance()).clear();
    await app.main();
    await tester.pump();
    final auth = await UserWebclient().login(
        mail: const String.fromEnvironment('E2E_EMAIL'),
        password: const String.fromEnvironment('E2E_PASSWORD'));
    await Get.find<UserController>().savePrefs(auth);
    final clue = await LivingClueWebclient().fetchById(clueId);
    expect(clue.metadata?['imagem_capa_arquivo_id'], fileId);
    final fresh = await FileWebclient().access(fileId);
    final signedAt = fresh.queryParameters['X-Amz-Date'] ?? '';
    expect(signedAt.length, 16);
    final timestamp = DateTime.parse(
        '${signedAt.substring(0, 4)}-${signedAt.substring(4, 6)}-${signedAt.substring(6, 8)}T${signedAt.substring(9, 11)}:${signedAt.substring(11, 13)}:${signedAt.substring(13, 15)}Z');
    expect(timestamp.millisecondsSinceEpoch ~/ 1000 > expiredEpoch, isTrue,
        reason: 'A new signature must be generated after the old URL expired.');
    Get.offAllNamed('/living_clues/show', parameters: {'id': '$clueId'});
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    final images = find.descendant(
        of: find.byType(ClueCover), matching: find.byType(RawImage));
    for (var attempt = 0;
        attempt < 60 &&
            tester
                .widgetList<RawImage>(images)
                .every((image) => image.image == null);
        attempt++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(
        tester.widgetList<RawImage>(images).any((image) =>
            image.image != null &&
            image.image!.width == 320 &&
            image.image!.height == 180),
        isTrue,
        reason:
            'The private cover must render actual pixels using fresh authenticated access.');
    await tester.ensureVisible(find.byType(ClueCover));
    await tester.pumpAndSettle();
    await capture(tester, 'cover-after-signed-url-expiry');
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 8)));
}
