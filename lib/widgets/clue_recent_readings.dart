import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unisinos_usp_app/models/clue_observation.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';

const _accent = Color(0xFF9CE7DF);
const _muted = Color(0xFFA1AEC4);

/// A bounded snapshot, with manual refresh and no invented units or timestamps.
class ClueRecentReadings extends StatefulWidget {
  const ClueRecentReadings({super.key, required this.clue, this.loadReadings});
  final LivingClueModel clue;
  final Future<List<ClueReading>> Function(int id)? loadReadings;
  @override
  State<ClueRecentReadings> createState() => _ClueRecentReadingsState();
}

class _ClueRecentReadingsState extends State<ClueRecentReadings> {
  List<ClueReading>? _updated;
  bool _refreshing = false;
  String? _error;
  int _request = 0;

  @override
  void didUpdateWidget(ClueRecentReadings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clue != widget.clue) {
      _request++;
      _updated = null;
      _error = null;
      _refreshing = false;
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    final request = ++_request;
    final id = widget.clue.id;
    setState(() {
      _refreshing = true;
      _error = null;
    });
    try {
      final readings = widget.loadReadings == null
          ? (await LivingClueWebclient().fetchById(id)).sensorReadings
          : await widget.loadReadings!(id);
      if (mounted && request == _request) setState(() => _updated = readings);
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _error =
            'Não foi possível atualizar. As leituras já carregadas foram mantidas. Tente novamente.');
      }
    } finally {
      if (mounted && request == _request) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordered = (_updated ?? widget.clue.sensorReadings)
        .where((r) => r.clueId == null || r.clueId == widget.clue.id)
        .toList()
      ..sort((a, b) => b.id.compareTo(a.id));
    final recent = ordered.take(10).toList();
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(builder: (context, bounds) {
                    final title = Row(children: [
                      const Icon(Icons.sensors, color: _accent, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text('Leituras recentes',
                              style: Theme.of(context).textTheme.titleLarge))
                    ]);
                    final refresh = OutlinedButton.icon(
                        onPressed: _refreshing ? null : _refresh,
                        icon: _refreshing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.refresh, size: 18),
                        label: Text(_refreshing
                            ? 'Atualizando…'
                            : 'Atualizar leituras'));
                    return bounds.maxWidth < 560
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                title,
                                const SizedBox(height: 12),
                                refresh
                              ])
                        : Row(children: [
                            Expanded(child: title),
                            const SizedBox(width: 16),
                            refresh
                          ]);
                  }),
                  const SizedBox(height: 8),
                  const Text(
                      'Últimos envios recebidos para esta pista. Atualize para consultar novos registros.',
                      style: TextStyle(color: _muted, height: 1.5)),
                  if (_error != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Semantics(
                            liveRegion: true,
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: Color(0xFFF2C0A4))))),
                  const SizedBox(height: 16),
                  if (recent.isEmpty)
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child:
                            Text('Nenhuma leitura disponível neste detalhe.'))
                  else ...[
                    Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: const Color(0xFF102C35),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0x665EDCD1))),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('ÚLTIMA LEITURA RECEBIDA',
                                  style: TextStyle(
                                      color: _accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1)),
                              const SizedBox(height: 8),
                              Text(
                                  readingReceivedLabel(
                                      recent.first.registeredAt),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 16),
                              _ReadingContent(reading: recent.first),
                            ])),
                    if (recent.length > 1)
                      Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: ExpansionTile(
                            key: PageStorageKey(
                                'previous-readings-${widget.clue.id}'),
                            tilePadding: EdgeInsets.zero,
                            title: Text(
                                'Leituras anteriores (${recent.length - 1})'),
                            subtitle: const Text(
                                'Envios anteriores por ordem de recebimento',
                                style: TextStyle(color: _muted, fontSize: 12)),
                            children: recent
                                .skip(1)
                                .map((reading) => ExpansionTile(
                                      key: PageStorageKey(
                                          'reading-history-${widget.clue.id}-${reading.id}'),
                                      title: Text(readingReceivedLabel(
                                          reading.registeredAt)),
                                      subtitle: Text(
                                          'Registro #${reading.id}${reading.simulated ? ' • DADOS FICTÍCIOS' : ''}'),
                                      childrenPadding: const EdgeInsets.all(12),
                                      children: [
                                        _ReadingContent(reading: reading)
                                      ],
                                    ))
                                .toList(),
                          )),
                    const SizedBox(height: 12),
                    Text(
                        '${recent.length} ${recent.length == 1 ? 'registro recebido' : 'registros mais recentes'} · até 10 por consulta',
                        style: const TextStyle(color: _muted, fontSize: 12)),
                    const Text(
                        'Ordenados por ID de recebimento. Não é o histórico completo nem uma atualização em tempo real.',
                        style: TextStyle(
                            color: _muted, fontSize: 11, height: 1.5)),
                  ],
                ])));
  }
}

/// Retain the declared timezone rather than guessing one for legacy timestamps.
String readingReceivedLabel(String? raw) {
  if (raw == null || raw.isEmpty) return 'Horário de recebimento não informado';
  final match = RegExp(
          r'^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}:\d{2}:\d{2})(?:\.\d+)?(Z|[+-]\d{2}:\d{2})?$')
      .firstMatch(raw);
  if (match == null || DateTime.tryParse(raw) == null) {
    return observationTime(raw);
  }
  final zone = match[5] == 'Z'
      ? 'UTC'
      : match[5] == null
          ? 'fuso não informado'
          : 'UTC${match[5]}';
  return '${match[3]}/${match[2]}/${match[1]} às ${match[4]} · $zone';
}

class _ReadingContent extends StatelessWidget {
  const _ReadingContent({required this.reading});
  final ClueReading reading;
  static const labels = {
    'UmidadeSolo': 'Umidade do solo',
    'CO2': 'CO₂',
    'co2': 'CO₂',
    'Pressao': 'Pressão',
    'pressao': 'Pressão'
  };
  String get _scope => '${reading.clueId}-${reading.id}';
  @override
  Widget build(BuildContext context) {
    final fields = reading.measurements.entries.toList();
    final formatted = reading.payload == null
        ? (reading.raw.isEmpty ? 'Envio sem conteúdo.' : reading.raw)
        : const JsonEncoder.withIndent('  ').convert(reading.payload);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (reading.simulated)
        Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.science_outlined,
                      color: Color(0xFFEFBF79), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text('DADOS FICTÍCIOS · Demonstração',
                          style: TextStyle(
                              color: Color(0xFFEFBF79),
                              fontWeight: FontWeight.w600))),
                ])),
      if (fields.isNotEmpty)
        LayoutBuilder(builder: (context, bounds) {
          final columns = bounds.maxWidth < 520
              ? 1
              : bounds.maxWidth < 860
                  ? 2
                  : 3;
          final width = (bounds.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: fields
                  .take(12)
                  .map((entry) => SizedBox(
                      width: width,
                      child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: const Color(0xFF091B2A),
                              borderRadius: BorderRadius.circular(10)),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    labels[entry.key] ??
                                        entry.key.replaceAll('_', ' '),
                                    style: const TextStyle(
                                        color: _muted, fontSize: 12)),
                                const SizedBox(height: 8),
                                SelectableText(
                                    entry.value
                                        .toString()
                                        .replaceFirst('.', ','),
                                    key: PageStorageKey(
                                        'reading-value-$_scope-${entry.key}'),
                                    style: const TextStyle(
                                        color: Color(0xFFE2F1F5),
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(reading.unit(entry.key),
                                    style: const TextStyle(
                                        color: _accent, fontSize: 13)),
                              ]))))
                  .toList());
        })
      else
        const Text('Formato sem interpretação disponível',
            style: TextStyle(color: _muted)),
      ExpansionTile(
          key: PageStorageKey('reading-payload-$_scope'),
          tilePadding: EdgeInsets.zero,
          title: const Text('Ver dados completos'),
          children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Text('Registro #${reading.id}',
                    style: const TextStyle(color: _muted, fontSize: 12))),
            Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    'Recebimento: ${observationTime(reading.registeredAt)}\n'
                    'Medição: ${observationTime(reading.measuredAt)}\n'
                    '${reading.origin} • ${reading.device}'
                    '${reading.payload?['alvo_medido'] == null ? '' : '\nAlvo declarado: ${reading.payload!['alvo_medido']}'}',
                    style: const TextStyle(
                        color: _muted, fontSize: 12, height: 1.5))),
            Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                    icon: const Icon(Icons.copy_outlined, size: 16),
                    label: const Text('Copiar dados'),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: reading.raw));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Dados recebidos copiados.')));
                      }
                    })),
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF050C18),
                constraints: const BoxConstraints(maxHeight: 260),
                child: SingleChildScrollView(
                    key: PageStorageKey('reading-scroll-$_scope'),
                    child: SelectableText(
                        formatted.length > 16000
                            ? '${formatted.substring(0, 16000)}…\nUse Copiar dados para consultar o envio integral.'
                            : formatted,
                        key: PageStorageKey('reading-raw-$_scope'),
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            height: 1.5)))),
          ]),
    ]);
  }
}
