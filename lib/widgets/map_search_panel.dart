import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:unisinos_usp_app/controllers/living_clue/living_clue_map_controller.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';

class MapSearchPanel extends StatefulWidget {
  const MapSearchPanel(
      {super.key,
      required this.controller,
      required this.onPoint,
      required this.onClue,
      required this.onClear});
  final LivingClueMapController controller;
  final void Function(LatLng) onPoint;
  final void Function(LivingClueModel) onClue;
  final VoidCallback onClear;
  @override
  State<MapSearchPanel> createState() => _MapSearchPanelState();
}

class _MapSearchPanelState extends State<MapSearchPanel> {
  final text = TextEditingController();
  Timer? debounce;
  bool expanded = true;
  @override
  void dispose() {
    debounce?.cancel();
    text.dispose();
    super.dispose();
  }

  void _changed(String value) {
    debounce?.cancel();
    setState(() => expanded = true);
    if (value.trim().isEmpty) {
      widget.onClear();
      return;
    }
    debounce = Timer(const Duration(milliseconds: 450),
        () => widget.controller.searchGlobal(value));
  }

  Future<void> _places() async {
    debounce?.cancel();
    final query = text.text.trim();
    if (query.length < 3) return;
    setState(() => expanded = true);
    await widget.controller.searchGlobal(query);
    if (mounted && widget.controller.activeSearch.value == query) {
      await widget.controller.searchPlaces(query);
    }
  }

  void _collapse() {
    FocusScope.of(context).unfocus();
    setState(() => expanded = false);
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
            controller: text,
            onChanged: _changed,
            onSubmitted: (_) => _places(),
            decoration: InputDecoration(
                labelText: 'Pesquisar pistas ou lugares',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                    tooltip: 'Limpar pesquisa',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      text.clear();
                      debounce?.cancel();
                      widget.onClear();
                      setState(() {});
                    }))),
        Obx(() {
          final c = widget.controller;
          if (c.activeSearch.isEmpty) return const SizedBox.shrink();
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(spacing: 12, children: [
                  TextButton(
                      onPressed: c.searchingPlaces.value ? null : _places,
                      child: Text(c.searchingPlaces.value
                          ? 'Buscando lugares…'
                          : 'Buscar lugares no mundo')),
                  TextButton(
                      onPressed: () => setState(() => expanded = !expanded),
                      child: Text(expanded
                          ? 'Recolher resultados'
                          : 'Mostrar resultados')),
                ]),
                if (c.isLoading.value) const LinearProgressIndicator(),
                if (expanded)
                  ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 165),
                      child: ListView(shrinkWrap: true, children: [
                        if (!c.isLoading.value && c.livingClues.isEmpty)
                          const ListTile(
                              dense: true,
                              title:
                                  Text('Nenhuma pista encontrada no acervo.')),
                        ...c.livingClues.map((clue) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_outlined),
                            title: Text(clue.name),
                            subtitle: const Text('Pista do acervo'),
                            onTap: () {
                              _collapse();
                              if (clue.hasLocation)
                                widget.onPoint(
                                    LatLng(clue.latitude!, clue.longitude!));
                              widget.onClue(clue);
                            })),
                        ...c.mapPlaces.map((place) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.public),
                            title: Text(place.displayName),
                            subtitle:
                                const Text('Lugar externo • OpenStreetMap'),
                            onTap: () {
                              _collapse();
                              widget.onPoint(
                                  LatLng(place.latitude, place.longitude));
                            })),
                        if (c.placeMessage.isNotEmpty)
                          Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(c.placeMessage.value,
                                  style:
                                      Theme.of(context).textTheme.bodySmall)),
                      ])),
              ]);
        }),
      ]));
}
