import 'package:flutter_map/flutter_map.dart';
import 'package:unisinos_usp_app/models/nominatim_place_model.dart';
import 'package:unisinos_usp_app/webclients/nominatim_webclient.dart';
import 'package:unisinos_usp_app/webclients/preferences_webclient.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:unisinos_usp_app/models/category_model.dart';
import 'package:unisinos_usp_app/models/clue_connection_model.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/webclients/category_webclient.dart';
import 'package:unisinos_usp_app/webclients/clue_connection_webclient.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class LivingClueMapController extends GetxController {
  final LivingClueWebclient _webclient = LivingClueWebclient();
  final ClueConnectionWebclient _connectionWebclient =
      ClueConnectionWebclient();
  final CategoryWebclient _categoryWebclient = CategoryWebclient();

  final RxList<LivingClueModel> livingClues = <LivingClueModel>[].obs;
  final RxList<ClueConnectionModel> connections = <ClueConnectionModel>[].obs;
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();
  final Rxn<LatLng> sonarCenter = Rxn<LatLng>();
  final RxDouble sonarRadius = 500.0.obs;
  final RxnInt selectedCategoryId = RxnInt();
  bool _loadingConnections = false;
  int _serial = 0;
  final activeSearch = ''.obs;
  final mapPlaces = <NominatimPlaceModel>[].obs;
  final searchingPlaces = false.obs;
  final placeMessage = ''.obs;
  final editingEnabled = false.obs;
  Future<void> searchGlobal(String query) async {
    final serial = ++_serial;
    activeSearch.value = query.trim();
    sonarCenter.value = null;
    mapPlaces.clear();
    try {
      isLoading.value = true;
      final result = await _webclient.fetch(
          search: query.trim(), categoryId: selectedCategoryId.value);
      if (serial != _serial) return;
      livingClues.assignAll(result);
      await _loadConnections();
      errorMessage.value = null;
    } catch (_) {
      if (serial == _serial)
        errorMessage.value = 'Não foi possível pesquisar pistas.';
    } finally {
      if (serial == _serial) isLoading.value = false;
    }
  }

  Future<void> searchPlaces(String query) async {
    if (query.trim().length < 3 || searchingPlaces.value) return;
    final serial = _serial;
    searchingPlaces.value = true;
    try {
      final places = await NominatimWebclient().search(search: query);
      if (serial != _serial) return;
      mapPlaces.assignAll(places);
      placeMessage.value = places.isEmpty
          ? 'Nenhum lugar encontrado.'
          : 'Lugares: © OpenStreetMap contributors';
    } catch (_) {
      if (serial == _serial)
        placeMessage.value = 'Falha ao buscar lugares. Tente novamente.';
    } finally {
      searchingPlaces.value = false;
    }
  }

  Future<bool> updatePosition(LivingClueModel clue, LatLng position) async {
    if (!editingEnabled.value) return false;
    try {
      final fresh = await _webclient.fetchById(clue.id);
      fresh.latitude = position.latitude;
      fresh.longitude = position.longitude;
      final saved = await _webclient.update(fresh);
      final index = livingClues.indexWhere((item) => item.id == clue.id);
      if (index >= 0) livingClues[index] = saved;
      return true;
    } catch (_) {
      errorMessage.value =
          'Não foi possível reposicionar. A posição anterior foi mantida.';
      return false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadFilters();
  }

  Future<void> loadFilters() async {
    try {
      editingEnabled.value = await PreferencesWebclient().editingEnabled();
    } catch (_) {}
    try {
      categories.assignAll(await _categoryWebclient.fetch());
    } catch (_) {}
  }

  Future<void> loadByBounds(LatLngBounds bounds) async {
    final serial = ++_serial;
    sonarCenter.value = null;
    activeSearch.value = '';
    mapPlaces.clear();
    placeMessage.value = '';
    errorMessage.value = null;
    try {
      isLoading.value = true;
      final result = await _webclient.fetchByBounds(
        north: bounds.north,
        south: bounds.south,
        east: bounds.east,
        west: bounds.west,
        categoryId: selectedCategoryId.value,
      );
      if (serial != _serial) return;
      livingClues.assignAll(result);
      await _loadConnections();
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      if (serial == _serial) {
        errorMessage.value = 'Falha ao carregar pistas no mapa.';
      }
    } finally {
      if (serial == _serial) isLoading.value = false;
    }
  }

  Future<void> searchAround(LatLng center, double radiusMeters) async {
    final serial = ++_serial;
    activeSearch.value = '';
    mapPlaces.clear();
    errorMessage.value = null;
    sonarCenter.value = center;
    sonarRadius.value = radiusMeters;
    try {
      isLoading.value = true;
      final result = await _webclient.searchByRadius(
        latitude: center.latitude,
        longitude: center.longitude,
        radiusMeters: radiusMeters,
        categoryId: selectedCategoryId.value,
      );
      if (serial != _serial) return;
      livingClues.assignAll(result);
      await _loadConnections();
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      if (serial == _serial) {
        errorMessage.value = 'Falha ao buscar pelo raio informado.';
      }
    } finally {
      if (serial == _serial) isLoading.value = false;
    }
  }

  Future<LatLng?> currentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        errorMessage.value = 'Permissão de localização negada.';
        return null;
      }
      final Position position = await Geolocator.getCurrentPosition();
      return LatLng(position.latitude, position.longitude);
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      errorMessage.value = 'Não foi possível obter sua localização.';
      return null;
    }
  }

  Future<void> _loadConnections() async {
    if (_loadingConnections) return;
    _loadingConnections = true;
    try {
      connections.assignAll(await _connectionWebclient.fetch());
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
    } finally {
      _loadingConnections = false;
    }
  }
}
