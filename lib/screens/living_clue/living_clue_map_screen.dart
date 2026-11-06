import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisinos_usp_app/widgets/map_search_panel.dart';
import 'package:unisinos_usp_app/widgets/category_map_marker.dart';
import 'package:unisinos_usp_app/controllers/living_clue/environmental_layers_controller.dart';
import 'package:unisinos_usp_app/widgets/environmental_map_layers.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:unisinos_usp_app/controllers/living_clue/living_clue_map_controller.dart';
import 'package:unisinos_usp_app/models/ai_assistant_screen_context.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/services/ai_assistant_context_service.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';
import 'package:widgets_spo/widgets_spo.dart';

class LivingClueMapScreen extends StatefulWidget {
  const LivingClueMapScreen({super.key});
  @override
  State<LivingClueMapScreen> createState() => _LivingClueMapScreenState();
}

class _LivingClueMapScreenState extends State<LivingClueMapScreen> {
  static const String _screenName = 'Mapa de pistas';
  final LivingClueMapController _controller =
      Get.find<LivingClueMapController>();
  final MapController _mapController = MapController();
  final _environmentalController = Get.find<EnvironmentalLayersController>();
  LatLng _tapCenter = const LatLng(-29.718, -51.143);
  bool _isConnectingMode = false;
  bool _repositionMode = false;
  bool _savingPosition = false;
  LivingClueModel? _repositionClue;
  LatLng? _pendingPosition;
  Future<void> _tutorial() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted || (prefs.getBool('atopos_map_tutorial_v1') ?? false)) return;
    await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Explore o mapa'),
                content: const Text(
                    'Pesquise pistas pelo nome ou busque lugares no mundo. Use Camadas para combinar dados ambientais. '
                    'Pressione e segure um ponto para definir o centro da busca por raio. Usuários com edição ativa podem criar conexões e reposicionar pistas.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Entendi'))
                ]));
    await prefs.setBool('atopos_map_tutorial_v1', true);
  }

  void _focus(LatLng point) {
    _mapController.move(point, 15);
  }

  Future<void> _savePosition() async {
    if (_savingPosition || _repositionClue == null || _pendingPosition == null)
      return;
    setState(() => _savingPosition = true);
    final saved =
        await _controller.updatePosition(_repositionClue!, _pendingPosition!);
    if (!mounted) return;
    setState(() {
      _savingPosition = false;
      if (saved) {
        _repositionMode = false;
        _repositionClue = null;
        _pendingPosition = null;
      }
    });
  }

  void _markerLegend() => showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
              child: ListView(shrinkWrap: true, children: [
            const ListTile(title: Text('Categorias no mapa')),
            ..._controller.categories.map((category) => ListTile(
                leading: CategoryMapMarker(
                    color: _hex(category.colorHex),
                    icon: categoryMapIcon(category)),
                title: Text(category.name))),
          ])));
  Color _hex(String value) {
    final hex = value.replaceFirst('#', '');
    return RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(hex)
        ? Color(int.parse('FF$hex', radix: 16))
        : Colors.teal;
  }

  LivingClueModel? _connectionSource;
  LivingClueModel? _connectionTarget;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentBounds();
      _environmentalController.openWithSatellite();
      _tutorial();
    });
  }

  Future<void> _loadCurrentBounds() async {
    await _controller.loadByBounds(_mapController.camera.visibleBounds);
  }

  Future<void> _useCurrentLocation() async {
    final position = await _controller.currentLocation();
    if (position != null) {
      _mapController.move(position, 14);
      _tapCenter = position;
      await _controller.searchAround(position, _controller.sonarRadius.value);
    }
  }

  Future<void> _searchByTap() async {
    await _controller.searchAround(_tapCenter, _controller.sonarRadius.value);
    _mapController.move(_tapCenter, _mapController.camera.zoom);
  }

  void _toggleConnectionMode() {
    setState(() {
      final nextValue = !_isConnectingMode;
      _isConnectingMode = nextValue;
      if (!nextValue) {
        _connectionSource = null;
        _connectionTarget = null;
      }
    });
  }

  void _cancelConnectionMode() {
    setState(() {
      _isConnectingMode = false;
      _connectionSource = null;
      _connectionTarget = null;
    });
  }

  Future<void> _handleMarkerTap(LivingClueModel item) async {
    if (_repositionMode) {
      setState(() {
        _repositionClue = item;
        _pendingPosition = null;
      });
      return;
    }
    if (!_isConnectingMode) {
      _showClueSheet(item);
      return;
    }

    if (_connectionSource == null) {
      setState(() {
        _connectionSource = item;
        _connectionTarget = null;
      });
      Get.customSnackbar(
        'Nova conexão',
        'Origem selecionada. Agora toque na pista de destino.',
      );
      return;
    }

    if (_connectionSource!.id == item.id) {
      Get.customSnackbar(
        'Atenção',
        'Selecione uma pista diferente como destino.',
      );
      return;
    }

    setState(() {
      _connectionTarget = item;
    });

    final created = await Get.toNamed(
      '/clue_connections/create',
      arguments: {
        'sourceId': _connectionSource!.id,
        'sourceName': _connectionSource!.name,
        'targetId': item.id,
        'targetName': item.name,
      },
    );

    if (!mounted) return;

    if (created == true) {
      await _loadCurrentBounds();
      _cancelConnectionMode();
      Get.successSnackbar('Conexão criada e mapa atualizado.');
      return;
    }

    setState(() {
      _connectionTarget = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    Get.find<AiAssistantContextService>().registerProvider(
      Get.currentRoute,
      _buildAiContext,
    );
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        leading: const SafeBackButton(),
        title: const Text('Mapa de pistas'),
        actions: [
          IconButton(
              tooltip: 'Ajuda do mapa',
              icon: const Icon(Icons.help_outline),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('atopos_map_tutorial_v1');
                _tutorial();
              }),
          Obx(() => IconButton(
              tooltip: 'Reposicionar pista',
              icon: const Icon(Icons.edit_location_alt_outlined),
              onPressed: _controller.editingEnabled.value
                  ? () => setState(() {
                        _repositionMode = !_repositionMode;
                        _isConnectingMode = false;
                        _repositionClue = null;
                        _pendingPosition = null;
                      })
                  : null)),
          if (_isConnectingMode)
            IconButton(
              tooltip: 'Cancelar nova conexão',
              icon: const Icon(Icons.close),
              onPressed: _cancelConnectionMode,
            )
          else
            IconButton(
              tooltip: 'Criar conexão no mapa',
              icon: const Icon(Icons.hub_outlined),
              onPressed: () {
                if (_controller.editingEnabled.value)
                  _toggleConnectionMode();
                else
                  Get.customSnackbar('Edição desativada',
                      'Ative criação e edição em Meu perfil.');
              },
            ),
          IconButton(
            icon: const Icon(Icons.add_location_alt),
            onPressed: () async {
              if (!_controller.editingEnabled.value) {
                Get.customSnackbar('Edição desativada',
                    'Ative criação e edição em Meu perfil.');
                return;
              }
              final center = _mapController.camera.center;
              final created = await Get.toNamed(
                '/living_clues/map/create',
                arguments: {
                  'latitude': center.latitude,
                  'longitude': center.longitude,
                },
              );
              if (created == true) _loadCurrentBounds();
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          Column(
            children: [
              MapSearchPanel(
                  controller: _controller,
                  onPoint: _focus,
                  onClue: (clue) => _handleMarkerTap(clue),
                  onClear: _loadCurrentBounds),
              if (_repositionMode)
                Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(_repositionClue == null
                              ? 'Toque na pista que deseja reposicionar.'
                              : 'Selecionada: ${_repositionClue!.name}. Pressione e segure a nova posição no mapa.'),
                          Wrap(spacing: 12, children: [
                            if (_pendingPosition != null)
                              FilledButton(
                                  onPressed:
                                      _savingPosition ? null : _savePosition,
                                  child: Text(_savingPosition
                                      ? 'Salvando…'
                                      : 'Confirmar nova posição')),
                            TextButton(
                                onPressed: () => setState(() {
                                      _repositionMode = false;
                                      _repositionClue = null;
                                      _pendingPosition = null;
                                    }),
                                child: const Text('Cancelar reposicionamento')),
                          ]),
                        ])),
              if (_isConnectingMode)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    _connectionSource == null
                        ? 'Modo nova conexão: toque na pista de origem.'
                        : 'Origem: ${_connectionSource!.name}. Agora toque na pista de destino.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Obx(
                  () => Column(
                    children: [
                      DropdownButtonFormField<int?>(
                        value: _controller.selectedCategoryId.value,
                        dropdownColor: Colors.grey.shade900,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Todas as categorias'),
                          ),
                          ..._controller.categories.map(
                            (c) => DropdownMenuItem<int?>(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          ),
                        ],
                        onChanged: (value) async {
                          _controller.selectedCategoryId.value = value;
                          await _loadCurrentBounds();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.radar,
                            size: 18,
                            color: Colors.indigo,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Raio',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Obx(
                              () => Slider(
                                activeColor: Colors.indigo,
                                value: _controller.sonarRadius.value,
                                min: 100,
                                max: 2000,
                                divisions: 19,
                                label:
                                    '${_controller.sonarRadius.value.toInt()} m',
                                onChanged: (value) =>
                                    _controller.sonarRadius.value = value,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      color: Colors.white,
                      icon: const Icon(Icons.my_location),
                      onPressed: _useCurrentLocation,
                    ),
                    IconButton(
                      color: Colors.white,
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadCurrentBounds,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  final markers = _controller.livingClues
                      .where((item) => item.hasLocation)
                      .map(
                        (item) => Marker(
                          point: LatLng(item.latitude!, item.longitude!),
                          width: 52,
                          height: 52,
                          child: Tooltip(
                              message: item.name,
                              child: GestureDetector(
                                onTap: () => _handleMarkerTap(item),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (_connectionSource?.id == item.id)
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.blue
                                              .withValues(alpha: 0.22),
                                          border: Border.all(
                                            color: Colors.blueAccent,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    if (_connectionTarget?.id == item.id)
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.orange
                                              .withValues(alpha: 0.22),
                                          border: Border.all(
                                            color: Colors.orangeAccent,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    CategoryMapMarker(
                                        color: _categoryColor(item),
                                        icon: categoryMapIcon(item.category)),
                                  ],
                                ),
                              )),
                        ),
                      )
                      .toList();
                  final pointsById = {
                    for (final clue in _controller.livingClues
                        .where((item) => item.hasLocation))
                      clue.id: LatLng(clue.latitude!, clue.longitude!),
                  };
                  final connectionLines = _controller.connections
                      .map((conn) {
                        final start = pointsById[conn.sourceClueId];
                        final end = pointsById[conn.targetClueId];
                        if (start == null || end == null) return null;
                        return Polyline(
                          points: [start, end],
                          color: Colors.red.shade600,
                          strokeWidth: 3,
                        );
                      })
                      .whereType<Polyline>()
                      .toList();

                  if (_connectionSource?.hasLocation == true &&
                      _connectionTarget?.hasLocation == true) {
                    final sourcePoint = pointsById[_connectionSource!.id] ??
                        LatLng(
                          _connectionSource!.latitude!,
                          _connectionSource!.longitude!,
                        );
                    final targetPoint = pointsById[_connectionTarget!.id] ??
                        LatLng(
                          _connectionTarget!.latitude!,
                          _connectionTarget!.longitude!,
                        );
                    connectionLines.add(
                      Polyline(
                        points: [sourcePoint, targetPoint],
                        color: Colors.orangeAccent,
                        strokeWidth: 4,
                      ),
                    );
                  }

                  final circles = <CircleMarker>[];
                  if (_controller.sonarCenter.value != null) {
                    circles.add(
                      CircleMarker(
                        point: _controller.sonarCenter.value!,
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderStrokeWidth: 1,
                        borderColor: Colors.blue,
                        radius: _controller.sonarRadius.value,
                        useRadiusInMeter: true,
                      ),
                    );
                  }
                  return Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _tapCenter,
                          initialZoom: 13,
                          onMapEvent: (event) {
                            if (event is MapEventMoveEnd &&
                                _controller.activeSearch.isEmpty &&
                                !_repositionMode &&
                                _controller.sonarCenter.value == null)
                              _loadCurrentBounds();
                          },
                          onLongPress: (tapPos, latLng) {
                            if (_repositionMode && _repositionClue != null) {
                              setState(() => _pendingPosition = latLng);
                              return;
                            }
                            setState(() => _tapCenter = latLng);
                            _controller.sonarCenter.value = latLng;
                          },
                        ),
                        children: [
                          EnvironmentalMapTiles(
                              controller: _environmentalController),
                          if (circles.isNotEmpty) CircleLayer(circles: circles),
                          if (connectionLines.isNotEmpty)
                            PolylineLayer(polylines: connectionLines),
                          MarkerLayer(markers: [
                            ...markers,
                            if (_pendingPosition != null)
                              Marker(
                                  point: _pendingPosition!,
                                  child: const Icon(Icons.edit_location_alt,
                                      color: Colors.orange, size: 40)),
                          ]),
                        ],
                      ),
                      Positioned(
                          left: 10,
                          top: 10,
                          child: Column(children: [
                            IconButton.filledTonal(
                                tooltip: 'Aproximar',
                                icon: const Icon(Icons.add),
                                onPressed: () => _mapController.move(
                                    _mapController.camera.center,
                                    (_mapController.camera.zoom + 1)
                                        .clamp(2, 19))),
                            IconButton.filledTonal(
                                tooltip: 'Afastar',
                                icon: const Icon(Icons.remove),
                                onPressed: () => _mapController.move(
                                    _mapController.camera.center,
                                    (_mapController.camera.zoom - 1)
                                        .clamp(2, 19))),
                            IconButton.filledTonal(
                                tooltip: 'Legenda dos marcadores',
                                icon: const Icon(Icons.category_outlined),
                                onPressed: _markerLegend),
                          ])),
                      EnvironmentalMapControls(
                          controller: _environmentalController),
                      if (_controller.isLoading.value)
                        const Positioned.fill(
                          child: IgnorePointer(
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.radar),
                          label: const Text('Buscar por raio'),
                          onPressed: _searchByTap,
                        ),
                      ),
                      if (_controller.errorMessage.value != null)
                        Positioned(
                          top: 12,
                          left: 16,
                          right: 16,
                          child: Card(
                            color: Colors.red.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                _controller.errorMessage.value!,
                                style: TextStyle(color: Colors.red.shade800),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  AiAssistantScreenContext _buildAiContext() => AiAssistantScreenContext(
        screenName: _screenName,
        route: Get.currentRoute,
        stage: 'exploração do mapa',
        goal: 'buscar pistas próximas e iniciar o cadastro de um novo ponto',
        visibleFields: const <String>[
          'mapa',
          'camadas ambientais',
          'mapa-base de ruas ou satélite',
          'opacidade e legenda',
          'raio do sonar',
          'buscar por raio',
          'usar minha localização',
          'criar pista por ponto',
        ],
        filledFields: <String, String>{
          'camadas ambientais ativas': _environmentalController.activeLayers
              .map((layer) => layer.name)
              .join(', '),
          'mapa-base': _environmentalController.selectedBaseMapId.value,
          'raio do sonar': '${_controller.sonarRadius.value.toInt()} m',
          'centro selecionado':
              '${_tapCenter.latitude.toStringAsFixed(5)}, ${_tapCenter.longitude.toStringAsFixed(5)}',
          'pistas carregadas': _controller.livingClues.length.toString(),
          'conexões visíveis': _controller.connections.length.toString(),
          'modo criação de conexão': _isConnectingMode ? 'ativo' : 'inativo',
          if (_connectionSource != null)
            'origem da conexão': _connectionSource!.name,
          if (_connectionTarget != null)
            'destino da conexão': _connectionTarget!.name,
        },
        notes: <String>[
          if (_controller.sonarCenter.value != null)
            'O usuário definiu um centro para busca por raio.',
          if (_isConnectingMode)
            'O usuário está criando uma conexão diretamente no mapa.',
        ],
      );

  Color _categoryColor(LivingClueModel model) {
    final String? hex = model.category?.colorHex;
    if (hex == null || hex.isEmpty) return Colors.redAccent;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (_) {
      return Colors.redAccent;
    }
  }

  void _showClueSheet(LivingClueModel model) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(model.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(model.category?.name ?? 'Categoria ${model.categoryId}'),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.visibility),
                label: const Text('Ver'),
                onPressed: () {
                  Get.back();
                  Get.toNamed('/living_clues/show', arguments: model);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
