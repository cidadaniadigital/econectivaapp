import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisinos_usp_app/controllers/living_clue/environmental_layers_controller.dart';
import 'package:unisinos_usp_app/controllers/living_clue/living_clue_map_controller.dart';
import 'package:unisinos_usp_app/screens/living_clue/living_clue_map_screen.dart';
import 'package:unisinos_usp_app/services/ai_assistant_context_service.dart';
import 'fauna_test.dart' show FaunaFake, faunaResult;

class TestMap extends LivingClueMapController {
  @override
  Future<void> loadFilters() async {}
  @override
  Future<void> loadByBounds(LatLngBounds bounds) async {}
}

class TestLayers extends EnvironmentalLayersController {
  @override
  Future<void> load({bool force = false}) async {}
}

class OfflineTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII='));
}

void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets('USP fauna layer, details and disable all at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({'atopos_map_tutorial_v1': true});
      Get.put<LivingClueMapController>(TestMap());
      Get.put<EnvironmentalLayersController>(TestLayers());
      Get.put(AiAssistantContextService());
      final source = FaunaFake();
      await tester.pumpWidget(GetMaterialApp(
          home: LivingClueMapScreen(
              faunaSource: source, tileProvider: OfflineTiles())));
      await tester.pumpAndSettle();
      expect(source.mapResponses, isEmpty);
      await tester.tap(find.textContaining('Camadas ('));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fauna observada · iNaturalist'));
      await tester.pump(const Duration(milliseconds: 1));
      expect(source.mapResponses.length, 1);
      source.mapResponses.single.complete(faunaResult(1));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Fechar camadas'));
      await tester.pumpAndSettle();
      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      map.mapController!.move(const LatLng(-29.79, -51.15), 13);
      await tester.pump(const Duration(milliseconds: 701));
      source.mapResponses.last.complete(faunaResult(2));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tapicuru 2 · localização aproximada'));
      await tester.pumpAndSettle();
      expect(find.text('Ver no iNaturalist'), findsOneWidget);
      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Camadas ('));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desativar todas'));
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
          isFalse);
      await tester.tap(find.byTooltip('Fechar camadas'));
      await tester.pumpAndSettle();
      expect(
          find.byTooltip('Tapicuru 2 · localização aproximada'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      Get.reset();
    });
  }
}
