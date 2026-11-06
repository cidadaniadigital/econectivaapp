import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';

class MapPointPickerScreen extends StatefulWidget {
  const MapPointPickerScreen({super.key});

  @override
  State<MapPointPickerScreen> createState() => _MapPointPickerScreenState();
}

class _MapPointPickerScreenState extends State<MapPointPickerScreen> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(-29.718, -51.143);
  LatLng? _selected;
  bool _loadingLocation = false;
  String _title = 'Selecionar ponto no mapa';

  @override
  void initState() {
    super.initState();
    _prefillFromArgs();
  }

  void _prefillFromArgs() {
    final args = Get.arguments;
    if (args is! Map) return;

    final dynamic title = args['title'];
    final dynamic latitude = args['latitude'];
    final dynamic longitude = args['longitude'];

    if (title is String && title.trim().isNotEmpty) {
      _title = title.trim();
    }

    if (latitude is num && longitude is num) {
      _center = LatLng(latitude.toDouble(), longitude.toDouble());
      _selected = _center;
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      setState(() => _loadingLocation = true);
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        Get.snackbar(
          'Permissão necessária',
          'Habilite a localização para usar sua posição atual.',
        );
        return;
      }

      final Position position = await Geolocator.getCurrentPosition();
      final LatLng point = LatLng(position.latitude, position.longitude);
      setState(() {
        _center = point;
        _selected = point;
      });
      _mapController.move(point, 15);
    } catch (_) {
      Get.snackbar('Localização', 'Não foi possível obter sua localização.');
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  void _onLongPress(TapPosition tapPosition, LatLng latLng) {
    setState(() => _selected = latLng);
  }

  void _clearSelection() {
    setState(() => _selected = null);
  }

  void _confirmSelection() {
    if (_selected == null) {
      Get.snackbar(
        'Selecione um ponto',
        'Pressione e segure no mapa para marcar a localização.',
      );
      return;
    }

    Get.back(result: <String, double>{
      'latitude': _selected!.latitude,
      'longitude': _selected!.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedText = _selected == null
        ? 'Nenhum ponto selecionado'
        : 'Ponto: ${_selected!.latitude.toStringAsFixed(6)}, ${_selected!.longitude.toStringAsFixed(6)}';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: const SafeBackButton(),
        title: Text(_title),
        actions: [
          IconButton(
            tooltip: 'Usar minha localização',
            icon: _loadingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            onPressed: _loadingLocation ? null : _useCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              onLongPress: _onLongPress,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.br.spotecnologia.uniuspapp',
              ),
              if (_selected != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _selected!,
                      color: Colors.blue.withValues(alpha: 0.25),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 2,
                      radius: 18,
                    ),
                  ],
                ),
              if (_selected != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selected!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                        size: 36,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Segure no mapa para marcar latitude/longitude.'),
                    const SizedBox(height: 6),
                    Text(
                      selectedText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: _selected == null ? null : _clearSelection,
                          icon: const Icon(Icons.clear),
                          label: const Text('Remover ponto'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: _confirmSelection,
              icon: const Icon(Icons.check),
              label: const Text('Usar este ponto'),
            ),
          ),
        ],
      ),
    );
  }
}
