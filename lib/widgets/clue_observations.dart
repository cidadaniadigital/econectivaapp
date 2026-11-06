import 'dart:convert';
import 'package:unisinos_usp_app/widgets/clue_recent_readings.dart';
import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/models/clue_observation.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';
import 'package:url_launcher/url_launcher.dart';

class ClueObservations extends StatefulWidget {
  const ClueObservations({super.key, required this.clue});
  final LivingClueModel clue;
  @override
  State<ClueObservations> createState() => _ClueObservationsState();
}

class _ClueObservationsState extends State<ClueObservations> {
  List<Map> _layers = [];
  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final response = await WebClient.instance.get(
          '/environmental_layers', [ApiInterceptor(), TokenInterceptor()], {});
      final decoded = jsonDecode(response.body);
      if (mounted && decoded is List) {
        setState(() => _layers = decoded.whereType<Map>().toList());
      }
    } catch (_) {/* Stored snapshot references remain available. */}
  }

  Widget _section(String title, List<Widget> children) => Card(
      child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...children,
          ])));
  String _value(dynamic value) => value == null || value.toString().isEmpty
      ? 'Não informado'
      : value is num
          ? value.toStringAsFixed(2).replaceAll('.', ',')
          : value.toString();
  Widget _indicator(
      String field, List<String> spec, EnvironmentalSnapshot snapshot) {
    final source = snapshot.sources[spec[2]];
    Map? catalog;
    if (source is Map) {
      for (final layer in _layers) {
        if (layer['id']?.toString() == source['layer_id']?.toString()) {
          catalog = layer;
          break;
        }
      }
    }
    final catalogSource = catalog?['source'];
    final url =
        catalogSource is Map ? Uri.tryParse('${catalogSource['url']}') : null;
    final validUrl =
        url != null && url.scheme == 'https' && url.host.isNotEmpty;
    final storedVersion = source is Map ? source['version']?.toString() : null;
    final catalogVersion =
        catalogSource is Map ? catalogSource['version']?.toString() : null;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(spec[0], style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(
              '${_value(snapshot.data[field])}${snapshot.data[field] == null || snapshot.data[field] == '' ? '' : ' ${spec[1]}'}',
              style: Theme.of(context).textTheme.titleMedium),
          Text(source is Map
              ? [
                  source['dataset'],
                  source['version'],
                  if (source['radius_m'] != null)
                    'Raio: ${source['radius_m']} m'
                ].where((v) => v != null && v.toString().isNotEmpty).join(' • ')
              : 'Fonte não informada'),
          if (validUrl)
            TextButton.icon(
                onPressed: () =>
                    launchUrl(url, mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(storedVersion != catalogVersion
                    ? 'Catálogo atual (versão diferente do snapshot)'
                    : 'Consultar fonte no catálogo')),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final clue = widget.clue;
    final snapshot = clue.environmentalContext;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _section('Contexto ambiental', [
        const Text(
            'Dados calculados para a localização e o entorno; não são características medidas da própria entidade.'),
        if (!clue.hasLocation)
          const Text('Sem localização informada.')
        else if (snapshot == null)
          const Text('Contexto ambiental indisponível.')
        else if (!snapshot.matches(clue.latitude, clue.longitude))
          const Text(
              'A análise disponível corresponde a outra localização. Aguardando contexto atualizado.')
        else if (snapshot.status != 'completed')
          Text({
                'pending': 'Análise pendente.',
                'processing': 'Análise em andamento.',
                'failed': 'Não foi possível obter o contexto ambiental.'
              }[snapshot.status] ??
              'Contexto indisponível.')
        else ...[
          Text(
              'Data da análise: ${snapshot.data['analyzed_at'] ?? 'não informada'}'),
          const Text(
              'A data é apresentada como recebida, sem presumir fuso horário.'),
          LayoutBuilder(
              builder: (context, bounds) => Wrap(
                  spacing: 20,
                  children: EnvironmentalSnapshot.indicators.entries
                      .map((e) => SizedBox(
                          width: bounds.maxWidth > 720
                              ? (bounds.maxWidth - 20) / 2
                              : bounds.maxWidth,
                          child: _indicator(e.key, e.value, snapshot)))
                      .toList())),
        ],
      ]),
      const SizedBox(height: 16),
      ClueRecentReadings(clue: clue),
    ]);
  }
}
