import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/living_clue/environmental_layers_controller.dart';
import 'package:unisinos_usp_app/models/environmental_layer_model.dart';
import 'package:widgets_spo/widgets_spo.dart';

/// Proxy requests use the application session; the GEOAPI secret stays server-side.
class EnvironmentalMapTiles extends StatelessWidget {
  const EnvironmentalMapTiles({super.key, required this.controller});
  final EnvironmentalLayersController controller;

  Widget _tiles(EnvironmentalLayerModel layer) => TileLayer(
        key: ValueKey('geo-${layer.id}-${controller.tileRevision.value}'),
        urlTemplate: controller.webclient.absoluteTileUrl(layer),
        tileProvider: NetworkTileProvider(headers: {
          'Authorization': 'Bearer ${AuthProvider.instance.getToken()}',
        }),
        minNativeZoom: layer.minZoom,
        maxNativeZoom: layer.maxZoom,
        minZoom: layer.minZoom.toDouble(),
        userAgentPackageName: 'com.br.spotecnologia.uniusp_app',
        errorTileCallback: (_, __, ___) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!controller.isClosed) controller.failedTileIds.add(layer.id);
          });
        },
      );

  @override
  Widget build(BuildContext context) => Obx(() {
        final base = controller.selectedExternalBaseMap;
        return Stack(fit: StackFit.expand, children: [
          if (base == null)
            TileLayer(
                key: const ValueKey('basemap-osm'),
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.br.spotecnologia.uniusp_app')
          else
            _tiles(base),
          ...controller.activeLayers.map((layer) => Opacity(
                key: ValueKey('overlay-${layer.id}'),
                opacity: controller.opacities[layer.id] ?? layer.defaultOpacity,
                child: _tiles(layer),
              )),
        ]);
      });
}

class EnvironmentalLayersPanel extends StatelessWidget {
  const EnvironmentalLayersPanel({super.key, required this.controller});
  final EnvironmentalLayersController controller;

  @override
  Widget build(BuildContext context) => SafeArea(
          child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .75,
        child: Obx(() => Column(children: [
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    const Expanded(
                        child: Text('Camadas do mapa',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold))),
                    IconButton(
                        tooltip: 'Atualizar camadas',
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          controller.retryTiles();
                          controller.load(force: true);
                        }),
                    IconButton(
                        tooltip: 'Fechar camadas',
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context)),
                  ])),
              if (controller.isLoading.value) const LinearProgressIndicator(),
              if (controller.errorMessage.value != null)
                Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                        '${controller.errorMessage.value} Use Atualizar camadas para tentar novamente.')),
              Expanded(
                  child: ListView(children: [
                const ListTile(title: Text('Mapa-base')),
                RadioGroup<String>(
                    groupValue: controller.selectedBaseMapId.value,
                    onChanged: (id) {
                      if (id != null) controller.selectBaseMap(id);
                    },
                    child: Column(children: [
                      const RadioListTile<String>(
                          value: 'osm',
                          title: Text('Mapa de ruas'),
                          subtitle: Text('OpenStreetMap')),
                      ...controller.baseMaps.map((layer) =>
                          RadioListTile<String>(
                              value: layer.id,
                              enabled: layer.available,
                              title: Text(layer.name),
                              subtitle: Text(layer.available
                                  ? layer.description
                                  : 'Temporariamente indisponível'))),
                    ])),
                ListTile(
                    title: const Text('Camadas ambientais'),
                    trailing: TextButton(
                        onPressed: controller.activeLayers.isEmpty
                            ? null
                            : controller.disableAll,
                        child: const Text('Desativar todas'))),
                if (controller.overlayLayers.isEmpty &&
                    !controller.isLoading.value &&
                    controller.errorMessage.value == null)
                  const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                          'Nenhuma camada ambiental disponível no momento.')),
                ...controller.overlayLayers.map((layer) {
                  final enabled = controller.enabledIds.contains(layer.id);
                  return ExpansionTile(
                    leading: Semantics(
                        label: 'Exibir ${layer.name}',
                        child: Switch(
                            value: enabled,
                            onChanged: layer.available
                                ? (value) => controller.toggle(layer.id, value)
                                : null)),
                    title: Text(layer.name),
                    subtitle: Text(layer.available
                        ? layer.description
                        : 'Temporariamente indisponível'),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Row(children: [
                        const Text('Opacidade'),
                        Expanded(
                            child: Slider(
                                label:
                                    '${((controller.opacities[layer.id] ?? layer.defaultOpacity) * 100).round()}%',
                                value: controller.opacities[layer.id] ??
                                    layer.defaultOpacity,
                                onChanged: enabled && layer.available
                                    ? (value) =>
                                        controller.setOpacity(layer.id, value)
                                    : null))
                      ]),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                              'Fonte: ${layer.sourceName} — ${layer.sourceVersion}',
                              style: Theme.of(context).textTheme.bodySmall)),
                      EnvironmentalLayerLegend(layer: layer),
                    ],
                  );
                }),
              ])),
            ])),
      ));
}

class EnvironmentalLayerLegend extends StatelessWidget {
  const EnvironmentalLayerLegend({super.key, required this.layer});
  final EnvironmentalLayerModel layer;
  static Color color(String value) {
    final hex = value.replaceFirst('#', '');
    return RegExp(r'^[a-fA-F0-9]{6}$').hasMatch(hex)
        ? Color(int.parse('FF$hex', radix: 16))
        : Colors.grey;
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ...layer.legend.map((item) => Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(children: [
              Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 6),
                  color: color(item.color)),
              Expanded(
                  child:
                      Text(item.label, style: const TextStyle(fontSize: 12))),
            ]))),
      ]);
}

class EnvironmentalMapControls extends StatelessWidget {
  const EnvironmentalMapControls({super.key, required this.controller});
  final EnvironmentalLayersController controller;

  void _panel(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => EnvironmentalLayersPanel(controller: controller));

  void _legend(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
              child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .6,
            child: Obx(() =>
                ListView(padding: const EdgeInsets.all(20), children: [
                  Text('Legenda das camadas',
                      style: Theme.of(context).textTheme.titleLarge),
                  ...controller.activeLayers.map((layer) => Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(layer.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            EnvironmentalLayerLegend(layer: layer),
                            Text('${layer.sourceName} — ${layer.sourceVersion}',
                                style: Theme.of(context).textTheme.bodySmall),
                          ]))),
                ])),
          )));

  @override
  Widget build(BuildContext context) => Obx(() => Stack(children: [
        Positioned(
            top: 12,
            right: 12,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              FilledButton.icon(
                  onPressed: () => _panel(context),
                  icon: const Icon(Icons.layers_outlined),
                  label: Text('Camadas (${controller.activeLayers.length})')),
              if (controller.activeLayers.isNotEmpty)
                FilledButton.tonalIcon(
                    onPressed: () => _legend(context),
                    icon: const Icon(Icons.legend_toggle),
                    label: const Text('Legenda')),
            ])),
        if (controller.failedTileIds.any((id) =>
            controller.activeLayers.any((layer) => layer.id == id) ||
            controller.selectedExternalBaseMap?.id == id))
          Positioned(
              top: 12,
              left: 12,
              child: Tooltip(
                  message:
                      'Alguns trechos das camadas não carregaram. Tentar novamente.',
                  child: IconButton.filledTonal(
                      onPressed: controller.retryTiles,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Tentar recarregar camadas'))),
        Positioned(
            bottom: 2,
            left: 4,
            right: 4,
            child: IgnorePointer(
                child: Align(
                    alignment: Alignment.centerRight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .9),
                          borderRadius: BorderRadius.circular(4)),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          child: Text(controller.baseMapAttribution,
                              style: const TextStyle(
                                  color: Colors.black87, fontSize: 10),
                              textAlign: TextAlign.right)),
                    )))),
      ]));
}
