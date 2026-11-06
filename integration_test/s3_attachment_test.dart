import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:widgets_spo/widgets_spo.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/models/file_model.dart';
import 'package:unisinos_usp_app/webclients/file_webclient.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('real private S3 attachment lifecycle through app client',
      (tester) async {
    expect(Uri.parse(WebClient.apiBaseUrl).host, '127.0.0.1');
    expect(const bool.fromEnvironment('E2E_REAL_S3'), isTrue);
    await app.main();
    await tester.pumpAndSettle();
    final auth = await UserWebclient().login(
        mail: const String.fromEnvironment('E2E_EMAIL'),
        password: const String.fromEnvironment('E2E_PASSWORD'));
    await Get.find<UserController>().savePrefs(auth);
    final clues = await LivingClueWebclient().fetch();
    final client = FileWebclient();
    final http = HttpClient();
    final checks = <String>[];
    final content =
        'Arquivo sintético UU-97 S3 ${DateTime.now().toUtc().toIso8601String()}\n';
    FileModel? uploaded;
    Uri? signed;
    try {
      uploaded = await client.upload(FileModel(
          id: 0,
          name: 'uu97-s3-test.txt',
          extension: 'txt',
          bytes: Uint8List.fromList(utf8.encode(content)),
          livingClueId: clues.first.id));
      checks.add('Upload multipart pelo FileWebclient');
      final listing = await WebClient.instance.get(
          '/files',
          [ApiInterceptor(), TokenInterceptor()],
          {'living_clue_id': clues.first.id.toString()});
      final raw = (jsonDecode(listing.body) as List)
          .firstWhere((f) => f['id'] == uploaded!.id);
      expect(raw['storage_provider'], 's3');
      checks.add('API confirmou storage_provider=s3');
      expect(
          (await client.fetch(livingClueId: clues.first.id))
              .any((f) => f.id == uploaded!.id),
          isTrue);
      signed = await client.access(uploaded.id);
      expect(signed.scheme, 'https');
      expect(signed.queryParameters['X-Amz-Expires'], '300');
      final downloaded = await (await http.getUrl(signed)).close();
      expect(downloaded.statusCode, 200);
      expect(await utf8.decodeStream(downloaded), content);
      checks.add(
          'URL assinada de 300 segundos: download HTTPS 200 e conteúdo idêntico');
      final unsigned =
          await (await http.getUrl(signed.replace(query: ''))).close();
      expect(unsigned.statusCode, 403);
      await unsigned.drain<void>();
      checks.add('Acesso direto sem assinatura negado com 403');
      final unauthorized = await (await http.getUrl(
              Uri.parse('${WebClient.apiBaseUrl}/files/${uploaded.id}/access')))
          .close();
      expect(unauthorized.statusCode, 401);
      await unauthorized.drain<void>();
      checks.add('Endpoint de acesso sem autenticação negado com 401');
    } finally {
      if (uploaded != null) {
        await client.delete(uploaded.id);
        expect(
            (await client.fetch(livingClueId: clues.first.id))
                .any((f) => f.id == uploaded!.id),
            isFalse);
        checks.add('Registro removido pela API e ausente na listagem');
        if (signed != null) {
          final removed = await (await http.getUrl(signed)).close();
          expect(removed.statusCode, 404);
          await removed.drain<void>();
          checks.add('Objeto removido do S3: URL antes válida retornou 404');
        }
      }
      http.close(force: true);
    }
    File('docs/validation/s3-tests.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
      'passed': true,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'environment': 'API local com banco isolado e bucket S3 real',
      'checks': checks,
      'cleanup':
          'Anexo e objeto atual excluídos; não foram alteradas configurações ou políticas do bucket.'
    }));
  });
}
