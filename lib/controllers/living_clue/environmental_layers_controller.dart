import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisinos_usp_app/models/environmental_layer_model.dart';
import 'package:unisinos_usp_app/webclients/environmental_layer_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class EnvironmentalLayersController extends GetxController {
  static const _enabledKey = 'environmental_map_enabled_layers';
  static const _opacityPrefix = 'environmental_map_opacity_';
  static const _baseMapKey = 'environmental_map_base_map';
  final EnvironmentalLayerWebclient webclient = EnvironmentalLayerWebclient();
  final failedTileIds = <String>{}.obs;
  final tileRevision = 0.obs;
  void retryTiles() {
    failedTileIds.clear();
    tileRevision.value++;
  }

  final layers = <EnvironmentalLayerModel>[].obs;
  final enabledIds = <String>{}.obs;
  final opacities = <String, double>{}.obs;
  final selectedBaseMapId = 'osm'.obs;
  final isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  List<EnvironmentalLayerModel> get baseMaps =>
      layers.where((layer) => layer.mapRole == 'basemap').toList();

  List<EnvironmentalLayerModel> get overlayLayers =>
      layers.where((layer) => layer.mapRole != 'basemap').toList();

  EnvironmentalLayerModel? get selectedExternalBaseMap {
    if (selectedBaseMapId.value == 'osm') return null;
    return baseMaps.firstWhereOrNull(
      (layer) => layer.id == selectedBaseMapId.value && layer.available,
    );
  }

  String get baseMapAttribution {
    final attribution = selectedExternalBaseMap?.attribution;
    return attribution != null && attribution.isNotEmpty
        ? attribution
        : '© OpenStreetMap contributors';
  }

  List<EnvironmentalLayerModel> get activeLayers => overlayLayers
      .where((layer) => layer.available && enabledIds.contains(layer.id))
      .toList();

  Future<void> load({bool force = false}) async {
    if (isLoading.value || (!force && layers.isNotEmpty)) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final preferences = await SharedPreferences.getInstance();
      final loaded = await webclient.fetch();
      layers.assignAll(loaded);
      final savedBaseMap = preferences.getString(_baseMapKey) ?? 'osm';
      selectedBaseMapId.value = savedBaseMap == 'osm' ||
              loaded.any(
                (layer) =>
                    layer.id == savedBaseMap &&
                    layer.mapRole == 'basemap' &&
                    layer.available,
              )
          ? savedBaseMap
          : 'osm';
      enabledIds.assignAll(
        (preferences.getStringList(_enabledKey) ?? const <String>[]).where(
          (id) => loaded.any((layer) =>
              layer.id == id && layer.available && layer.mapRole != 'basemap'),
        ),
      );
      for (final layer in loaded) {
        opacities[layer.id] =
            (preferences.getDouble('$_opacityPrefix${layer.id}') ??
                    layer.defaultOpacity)
                .clamp(0.0, 1.0);
      }
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      errorMessage.value = 'Não foi possível carregar as camadas ambientais.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Each new map visit starts in orbital imagery when the provider is available.
  Future<void> openWithSatellite() async {
    await load();
    selectedBaseMapId.value =
        baseMaps.any((layer) => layer.id == 'satellite' && layer.available)
            ? 'satellite'
            : 'osm';
  }

  Future<void> toggle(String id, bool enabled) async {
    if (!overlayLayers.any((layer) => layer.id == id && layer.available)) {
      return;
    }
    enabled ? enabledIds.add(id) : enabledIds.remove(id);
    enabledIds.refresh();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_enabledKey, enabledIds.toList());
  }

  Future<void> selectBaseMap(String id) async {
    if (id != 'osm' &&
        !baseMaps.any((layer) => layer.id == id && layer.available)) {
      return;
    }
    selectedBaseMapId.value = id;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_baseMapKey, id);
  }

  Future<void> setOpacity(String id, double opacity) async {
    if (!opacity.isFinite || !overlayLayers.any((layer) => layer.id == id)) {
      return;
    }
    final bounded = opacity.clamp(0.0, 1.0);
    opacities[id] = bounded;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble('$_opacityPrefix$id', bounded);
  }

  Future<void> disableAll() async {
    enabledIds.clear();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_enabledKey, const []);
  }
}
