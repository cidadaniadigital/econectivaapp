import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisinos_usp_app/controllers/living_clue/environmental_layers_controller.dart';
import 'package:unisinos_usp_app/controllers/living_clue/living_clue_map_controller.dart';
import 'package:unisinos_usp_app/models/environmental_layer_model.dart';
import 'package:unisinos_usp_app/screens/living_clue/living_clue_map_screen.dart';
import 'package:unisinos_usp_app/services/ai_assistant_context_service.dart';
import 'package:unisinos_usp_app/widgets/environmental_map_layers.dart';
import 'fauna_map_integration_test.dart' show TestMap, TestLayers, OfflineTiles;

void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets(
        'USP catalog DETER toggle, authenticated tile URL, zoom, legend, opacity and disable all at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({'atopos_map_tutorial_v1': true});
      final layers = TestLayers();
      layers.layers.assignAll([
        EnvironmentalLayerModel.fromJson({
          'id': 'deter-amazonia',
          'name': 'Avisos DETER — Amazônia',
          'description':
              'Avisos dos últimos 365 dias; não representam a taxa PRODES. Cobertura: Amazônia. Amplie o mapa para visualizar.',
          'tile_url': '/api/environmental_tiles/deter-amazonia/{z}/{x}/{y}.png',
          'min_zoom': 10,
          'max_zoom': 18,
          'default_opacity': 0.75,
          'available': true,
          'legend': [
            {
              'label': 'Avisos de alteração da cobertura vegetal',
              'color': '#e34a33'
            }
          ],
          'source': {
            'name': 'INPE — DETER Amazônia',
            'version': '2026-11-19T12:00:00Z'
          },
        })
      ]);
      Get.put<LivingClueMapController>(TestMap());
      Get.put<EnvironmentalLayersController>(layers);
      Get.put(AiAssistantContextService());
      await tester.pumpWidget(GetMaterialApp(
          home: LivingClueMapScreen(tileProvider: OfflineTiles())));
      await tester.pumpAndSettle();
      expect(layers.enabledIds, isEmpty);
      await tester.tap(find.text('Camadas (0)'));
      await tester.pumpAndSettle();
      final toggle = find.byType(Switch).last;
      expect(tester.widget<Switch>(toggle).value, isFalse);
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(layers.activeLayers.single.id, 'deter-amazonia');
      final tile = find.byWidgetPredicate((w) =>
          w is TileLayer &&
          (w.urlTemplate?.contains('/deter-amazonia/') ?? false));
      expect(tile, findsOneWidget);
      final options = tester.widget<TileLayer>(tile);
      expect(options.urlTemplate,
          startsWith('https://api.atopos.spotec.app/api/environmental_tiles/'));
      expect(options.minZoom, 10);
      expect(options.maxNativeZoom, 18);
      await tester.tap(find.text('Avisos DETER — Amazônia'));
      await tester.pumpAndSettle();
      expect(find.text('Avisos de alteração da cobertura vegetal'),
          findsOneWidget);
      final slider = find.descendant(
          of: find.byType(EnvironmentalLayersPanel),
          matching: find.byType(Slider));
      await tester.ensureVisible(slider);
      await tester.pumpAndSettle();
      tester.widget<Slider>(slider).onChanged!(0.4);
      await tester.pumpAndSettle();
      expect(layers.opacities['deter-amazonia'], 0.4);
      final disable = find.text('Desativar todas');
      await tester.ensureVisible(disable);
      await tester.tap(disable);
      await tester.pumpAndSettle();
      expect(layers.enabledIds, isEmpty);
      expect(tile, findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      Get.reset();
    });
  }
}
