import 'dart:convert';
import 'package:unisinos_usp_app/services/collection_service.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'evidence_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/routes/routes.dart';
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:unisinos_usp_app/webclients/sample_webclient.dart';
import 'package:unisinos_usp_app/webclients/sample_detail_webclient.dart';
import 'package:unisinos_usp_app/models/sample_model.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';
import 'package:unisinos_usp_app/webclients/category_webclient.dart';
import 'package:unisinos_usp_app/webclients/clue_connection_webclient.dart';
import 'package:unisinos_usp_app/webclients/connection_type_webclient.dart';
import 'package:unisinos_usp_app/webclients/node_type_webclient.dart';
import 'package:unisinos_usp_app/webclients/node_webclient.dart';
import 'package:unisinos_usp_app/webclients/node_link_webclient.dart';
import 'package:unisinos_usp_app/webclients/chat_template_webclient.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('all registered screens against isolated current API',
      (tester) async {
    final base = Uri.parse(WebClient.apiBaseUrl);
    expect({'127.0.0.1', 'localhost'}, contains(base.host),
        reason: 'Test must never mutate production');
    const email = String.fromEnvironment('E2E_EMAIL');
    const password = String.fromEnvironment('E2E_PASSWORD');
    expect(email, isNotEmpty);
    expect(password, isNotEmpty);
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 1));
    final auth = await UserWebclient().login(mail: email, password: password);
    await Get.find<UserController>().savePrefs(auth);
    Get.offAllNamed('/home');
    await tester.pumpAndSettle();
    final clues = await LivingClueWebclient().fetch();
    final categories = await CategoryWebclient().fetch();
    final connections = await ClueConnectionWebclient().fetch();
    final types = await ConnectionTypeWebclient().fetch();
    final nodeTypes = await NodeTypeWebclient().fetch();
    final nodes = await NodeWebclient().fetch();
    final links = await NodeLinkWebclient().fetch();
    final templates = await ChatTemplateWebclient().fetch();
    final details = await SampleDetailWebclient().select('', 0, {});
    expect(details, isNotEmpty,
        reason: 'Prepare the isolated sample detail fixture before running');
    final sample = await SampleWebclient().create(SampleModel(
        id: 0,
        name: 'UU97 tela de amostra',
        sampleString: 'teste',
        sampleUnique: 'uu97-screen-${DateTime.now().microsecondsSinceEpoch}',
        sampleDetailId: details!.first.id,
        sampleDouble: 1,
        sampleDate: DateTime.utc(2026, 10, 22)));
    addTearDown(() => SampleWebclient().delete(sample.id));
    final userId = auth.id;
    final collectionCategory =
        (await CollectionService().category(create: true))!;
    final collection = await LivingClueWebclient().create(LivingClueModel(
        id: 0,
        name: 'USP coleção de rotas sintética',
        categoryId: collectionCategory.id));
    addTearDown(() => LivingClueWebclient().delete(collection.id));
    final routes = <Map<String, dynamic>>[
      {'route': '/catalog'},
      {'route': '/management'},
      {'route': '/collections/create'},
      {'route': '/collections/show', 'id': collection.id},
      {'route': '/home'},
      {'route': '/profile'},
      {'route': '/categories'},
      {'route': '/categories/create'},
      {'route': '/categories/update', 'id': categories.first.id},
      {'route': '/living_clues'},
      {'route': '/living_clues/type_select'},
      {'route': '/living_clues/pre_create'},
      {
        'route': '/living_clues/create',
        'args': {
          'categoryId': categories.first.id,
          'categoryName': categories.first.name,
          'metadataTags': categories.first.metadataTags
        }
      },
      {'route': '/living_clues/map'},
      {'route': '/living_clues/map/create'},
      {'route': '/map/point_picker'},
      for (final clue in clues.take(2)) ...[
        {'route': '/living_clues/show', 'args': clue},
        {'route': '/living_clues/update', 'id': clue.id},
        {'route': '/living_clues/connect', 'args': clue},
        {
          'route': '/living_clues/${clue.id}/chat',
          'args': {'model': clue}
        },
      ],
      {'route': '/clue_connections'},
      {'route': '/clue_connections/create'},
      if (connections.isNotEmpty)
        {'route': '/clue_connections/update', 'id': connections.first.id},
      {'route': '/connection_types'},
      {'route': '/connection_types/create'},
      if (types.isNotEmpty)
        {'route': '/connection_types/update', 'id': types.first.id},
      {'route': '/node_types'},
      {'route': '/node_types/create'},
      if (nodeTypes.isNotEmpty)
        {'route': '/node_types/update', 'id': nodeTypes.first.id},
      {'route': '/nodes'},
      {'route': '/nodes/create'},
      {'route': '/nodes/graph'},
      if (nodes.isNotEmpty) {'route': '/nodes/update', 'id': nodes.first.id},
      {'route': '/node_links'},
      {'route': '/node_links/create'},
      if (links.isNotEmpty)
        {'route': '/node_links/update', 'id': links.first.id},
      {'route': '/chat_templates'},
      {'route': '/chat_templates/create'},
      if (templates.isNotEmpty) ...[
        {'route': '/chat_templates/update', 'id': templates.first.id},
        {
          'route': '/chat_templates/chat',
          'id': templates.first.id,
          'args': templates.first
        },
        {'route': '/chat_templates/sources/create', 'id': templates.first.id},
      ],
      {'route': '/chat'},
      {'route': '/samples'},
      {'route': '/samples/create'},
      {'route': '/samples/update', 'id': sample.id},
      {'route': '/users'},
      {'route': '/users/create'},
      {'route': '/users/update', 'id': userId},
      {'route': '/create_account'},
      {'route': '/recover_password'},
      {'route': '/code_confirmation'},
      {'route': '/create_password', 'args': 'invalid-test-token'},
      {'route': '/password_recovery/invalid-test-token'},
      {'route': '/login'},
    ];
    final results = <Map<String, dynamic>>[];
    for (final entry in routes) {
      final route = entry['route'] as String;
      final errors = <String>[];
      debugPrint('SCREEN $route');
      try {
        Get.toNamed(route,
            arguments: entry['args'],
            parameters: entry['id'] == null ? null : {'id': '${entry['id']}'});
        await tester.pump();
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        Object? error;
        while ((error = tester.takeException()) != null) {
          errors.add(error.toString());
        }
        expect(Get.currentRoute.split('?').first, route,
            reason:
                'The requested screen must be shown rather than a redirect');
        expect(find.byType(Scaffold), findsWidgets);
        Get.back();
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
      } catch (error) {
        errors.add(error.toString());
      }
      results.add({
        'route': route,
        'id': entry['id'],
        'passed': errors.isEmpty,
        'errors': errors
      });
    }
    final output = await evidenceFile('screen-tests.json');
    output.parent.createSync(recursive: true);
    output
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(results));
    await publishEvidence('screen-tests.json', results);
    final visited = [
      '/splash',
      ...routes.map((entry) => entry['route'] as String)
    ];
    final registered = appRoutes().map((page) => page.name).toList();
    final missing = registered.where((pattern) {
      final parts = Uri.parse(pattern).pathSegments;
      return !visited.any((route) {
        final actual = Uri.parse(route).pathSegments;
        if (parts.length != actual.length) return false;
        for (var i = 0; i < parts.length; i++) {
          if (!parts[i].startsWith(':') && parts[i] != actual[i]) return false;
        }
        return true;
      });
    }).toList();
    (await evidenceFile('route-coverage.json')).writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
      'registered_routes': registered,
      'scenarios': results.length,
      'missing': missing
    }));
    await publishEvidence('route-coverage.json', {'registered_routes':registered,'scenarios':results.length,'missing':missing});
    expect(missing, isEmpty,
        reason: 'Every registered screen must be included in the route sweep');
    final failed = results.where((r) => r['passed'] == false).toList();
    expect(failed, isEmpty,
        reason: const JsonEncoder.withIndent('  ').convert(failed));
  }, timeout: const Timeout(Duration(minutes: 10)));
}
