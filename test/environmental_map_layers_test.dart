import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisinos_usp_app/controllers/living_clue/environmental_layers_controller.dart';
import 'package:unisinos_usp_app/models/environmental_layer_model.dart';
import 'package:unisinos_usp_app/webclients/environmental_layer_webclient.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:unisinos_usp_app/widgets/environmental_map_layers.dart';

Map<String, dynamic> layer(String id,
        {bool available = true, String role = 'overlay'}) =>
    {
      'id': id,
      'name': id == 'satellite' ? 'Imagem de satélite' : id,
      'description': 'Descrição da camada',
      'available': available,
      'map_role': role,
      'tile_url': '/api/environmental_tiles/$id/{z}/{x}/{y}.png',
      'default_opacity': .6,
      'min_zoom': 3,
      'max_zoom': 16,
      'attribution': role == 'basemap' ? 'Imagem © Esri' : '',
      'source': {'name': 'IBGE', 'version': '2022'},
      'legend': [
        {'label': 'Pampa', 'color': '#43D4C2'}
      ],
    };

void main() {
  late http.Client original;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    original = WebClient.instance.client;
    WebClient.instance.client = MockClient((_) async => http.Response(
        jsonEncode([
          layer('satellite', role: 'basemap'),
          layer('Biomas'),
          layer('Indisponível', available: false)
        ]),
        200));
  });
  tearDown(() {
    WebClient.instance.client = original;
    Get.reset();
  });

  test('catalog separates basemaps and overlays and remembers valid choices',
      () async {
    SharedPreferences.setMockInitialValues({
      'environmental_map_enabled_layers': [
        'Biomas',
        'satellite',
        'Indisponível',
        'removed'
      ],
      'environmental_map_opacity_Biomas': .35,
    });
    final controller = EnvironmentalLayersController();
    await controller.openWithSatellite();
    expect(controller.selectedBaseMapId.value, 'satellite');
    expect(controller.baseMapAttribution, contains('Esri'));
    expect(controller.activeLayers.map((l) => l.id), ['Biomas']);
    expect(controller.enabledIds.contains('satellite'), isFalse);
    expect(controller.opacities['Biomas'], .35);
    await controller.toggle('Indisponível', true);
    expect(controller.enabledIds.contains('Indisponível'), isFalse);
    await controller.setOpacity('Biomas', .8);
    final restored = EnvironmentalLayersController();
    await restored.load();
    expect(restored.activeLayers.single.id, 'Biomas');
    expect(restored.opacities['Biomas'], .8);
    await restored.disableAll();
    expect(restored.activeLayers, isEmpty);
  });

  test('unavailable satellite falls back to streets and retry recovers catalog',
      () async {
    WebClient.instance.client =
        MockClient((_) async => http.Response('invalid', 200));
    final controller = EnvironmentalLayersController();
    await controller.openWithSatellite();
    expect(controller.errorMessage.value, isNotNull);
    expect(controller.selectedExternalBaseMap, isNull);
    WebClient.instance.client = MockClient((_) async => http.Response(
        jsonEncode([
          layer('satellite', role: 'basemap', available: false),
          layer('Biomas')
        ]),
        200));
    await controller.load(force: true);
    expect(controller.errorMessage.value, isNull);
    await controller.selectBaseMap('satellite');
    expect(controller.selectedBaseMapId.value, 'osm');
    expect(controller.baseMapAttribution, contains('OpenStreetMap'));
  });

  test('opacity is bounded and tiles cannot send the session to another host',
      () async {
    final controller = EnvironmentalLayersController();
    await controller.load();
    await controller.setOpacity('Biomas', 5);
    expect(controller.opacities['Biomas'], 1);
    await controller.setOpacity('Biomas', double.nan);
    expect(controller.opacities['Biomas'], 1);
    final client = EnvironmentalLayerWebclient();
    final valid = EnvironmentalLayerModel.fromJson(layer('Biomas'));
    expect(client.absoluteTileUrl(valid),
        '${WebClient.apiBaseUrl}/environmental_tiles/Biomas/{z}/{x}/{y}.png');
    final hostile = layer('Biomas')
      ..['tile_url'] = 'https://other.test/tiles/{z}/{x}/{y}.png';
    expect(
        () => client.absoluteTileUrl(EnvironmentalLayerModel.fromJson(hostile)),
        throwsFormatException);
  });

  testWidgets('panel toggles layers, shows legend and fits 320px',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = EnvironmentalLayersController();
    await controller.load();
    await tester.pumpWidget(GetMaterialApp(
        home:
            Scaffold(body: EnvironmentalLayersPanel(controller: controller))));
    await tester.pumpAndSettle();
    expect(controller.layers.length, 3);
    await tester.ensureVisible(find.text('Biomas', skipOffstage: false));
    await tester.pumpAndSettle();
    final switches = find.byType(Switch, skipOffstage: false);
    expect(switches, findsNWidgets(2));
    expect(tester.widget<Switch>(switches.last).onChanged, isNull);
    await tester.tap(switches.first);
    await tester.pumpAndSettle();
    expect(controller.activeLayers.single.id, 'Biomas');
    await tester.tap(find.text('Biomas'));
    await tester.pumpAndSettle();
    expect(find.text('Pampa'), findsOneWidget);
    expect(find.text('Fonte: IBGE — 2022'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
