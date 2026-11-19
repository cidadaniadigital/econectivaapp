import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unisinos_usp_app/webclients/deter_webclient.dart';

class DeterNearby extends StatefulWidget {
  final double latitude;
  final double longitude;
  final DeterSource? source;
  const DeterNearby({
    super.key,
    required this.latitude,
    required this.longitude,
    this.source,
  });
  @override
  State<DeterNearby> createState() => _DeterNearbyState();
}

class _DeterNearbyState extends State<DeterNearby> {
  late final DeterSource source = widget.source ?? DeterWebclient();
  int radius = 1000;
  int serial = 0;
  bool loading = true;
  Map<String, dynamic>? data;
  String? error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant DeterNearby oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++serial;
    setState(() {
      loading = true;
      error = null;
      data = null;
    });
    try {
      final value = await source.nearby(
        widget.latitude,
        widget.longitude,
        radius,
      );
      if (!mounted || request != serial) return;
      setState(() {
        data = value;
        loading = false;
      });
    } catch (_) {
      if (!mounted || request != serial) return;
      setState(() {
        loading = false;
        error = 'Não foi possível consultar os avisos DETER agora.';
      });
    }
  }

  String date(Object? value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed == null
        ? 'não informada'
        : DateFormat('dd/MM/yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final result = data;
    final classes = (result?['classes'] as List?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 28),
        const Row(
          children: [
            Icon(Icons.forest_outlined, color: Color(0xFFFFAA70)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Alterações da vegetação no entorno',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'INPE / TerraBrasilis — DETER Amazônia. Avisos de alteração da cobertura vegetal; não equivalem à taxa anual de desmatamento do PRODES.',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final value in [500, 1000, 5000])
              ChoiceChip(
                label: Text(value == 500 ? '500 m' : '${value ~/ 1000} km'),
                selected: radius == value,
                onSelected: (_) {
                  if (radius != value) {
                    radius = value;
                    _load();
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (loading)
          const LinearProgressIndicator()
        else if (error != null) ...[
          Text(error!),
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ] else if (result != null) ...[
          if (result['covered'] != true)
            const Text(
              'Esta localização está fora da cobertura DETER Amazônia desta integração.',
            )
          else ...[
            Text(
              (result['total'] as num? ?? 0) == 0
                  ? 'Nenhum aviso encontrado neste raio e período. Isso não comprova ausência de alterações ambientais.'
                  : '${result['total']} avisos no entorno e período consultados.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            for (final item in classes)
              Text(
                '${item['class_name'].toString().replaceAll('_', ' ')}: ${item['count']}',
              ),
          ],
          const SizedBox(height: 8),
          Text(
            'Período: ${date(result['period_start'])} a ${date(result['period_end'])}. Sincronizado em ${date(result['fetched_at'])}.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (result['stale'] == true)
            const Text(
              'Atualização pendente. Exibindo a última sincronização disponível.',
            ),
        ],
        TextButton.icon(
          onPressed: () => launchUrl(
            Uri.parse('https://terrabrasilis.dpi.inpe.br/'),
            mode: LaunchMode.externalApplication,
          ),
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text('Conhecer a fonte — INPE'),
        ),
      ],
    );
  }
}
