import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisinos_usp_app/widgets/category_map_marker.dart';
import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/controllers/living_clue/environmental_layers_controller.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/living_clue/living_clue_map_controller.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/screens/living_clue/living_clue_map_screen.dart';
import 'package:unisinos_usp_app/services/ai_assistant_context_service.dart';

class _MapController extends LivingClueMapController {
  int loads = 0;
  @override
  Future<void> loadFilters() async {}
  @override
  Future<void> loadByBounds(LatLngBounds bounds) async {
    loads++;
  }
}

class _LayersController extends EnvironmentalLayersController {
  @override
  Future<void> load({bool force = false}) async {}
}

void main() {
  testWidgets(
      'map connects located clues, ignores missing coordinates and reloads after save',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'atopos_map_tutorial_v1': true});
    final controller = _MapController();
    controller.editingEnabled.value = true;
    controller.livingClues.assignAll([
      LivingClueModel(
          id: 1,
          name: 'Origem',
          categoryId: 1,
          latitude: -29.718,
          longitude: -51.143),
      LivingClueModel(
          id: 2,
          name: 'Destino',
          categoryId: 1,
          latitude: -29.718,
          longitude: -51.120),
      LivingClueModel(id: 3, name: 'Sem localização', categoryId: 1),
    ]);
    Get.put<LivingClueMapController>(controller);
    Get.put<EnvironmentalLayersController>(_LayersController());
    Get.put(AiAssistantContextService());
    Map<dynamic, dynamic>? received;
    await tester.pumpWidget(
        GetMaterialApp(home: const LivingClueMapScreen(), getPages: [
      GetPage(
          name: '/clue_connections/create',
          page: () {
            received = Map<dynamic, dynamic>.from(Get.arguments as Map);
            return Builder(
                builder: (context) => Scaffold(
                        body: TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Confirmar teste'),
                    )));
          }),
    ]));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(find.byType(CategoryMapMarker), findsNWidgets(2));
    final initialLoads = controller.loads;
    await tester.tap(find.byTooltip('Criar conexão no mapa'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    await tester.tap(find.byType(CategoryMapMarker).first);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    await tester.tap(find.byType(CategoryMapMarker).last);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(received, {
      'sourceId': 1,
      'sourceName': 'Origem',
      'targetId': 2,
      'targetName': 'Destino'
    });
    await tester.tap(find.text('Confirmar teste'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(controller.loads, greaterThan(initialLoads));
    expect(find.byTooltip('Criar conexão no mapa'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    Get.reset();
  });
}
