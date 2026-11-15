import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unisinos_usp_app/models/fauna_model.dart';
import 'package:unisinos_usp_app/webclients/fauna_webclient.dart';

class FaunaNearby extends StatefulWidget {
  final double latitude;
  final double longitude;
  final FaunaSource? source;
  const FaunaNearby({
    super.key,
    required this.latitude,
    required this.longitude,
    this.source,
  });
  @override
  State<FaunaNearby> createState() => _FaunaNearbyState();
}

class _FaunaNearbyState extends State<FaunaNearby> {
  late final FaunaSource source = widget.source ?? FaunaWebclient();
  int radius = 1000;
  int serial = 0;
  bool loading = true;
  FaunaResult? result;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant FaunaNearby oldWidget) {
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
      result = null;
    });
    try {
      final loaded = await source.nearby(
        widget.latitude,
        widget.longitude,
        radius,
      );
      if (!mounted || request != serial) return;
      setState(() {
        result = loaded;
        loading = false;
      });
    } catch (_) {
      if (!mounted || request != serial) return;
      setState(() {
        loading = false;
        error = 'Não foi possível consultar a fauna agora.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 28),
          const Row(
            children: [
              Icon(Icons.pets_outlined, color: Color(0xFF72DBBE)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Fauna observada no entorno',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Registros do iNaturalist com fotos. Avistamentos em determinadas datas não garantem a presença atual dos animais.',
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
            const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Text('Consultando observações…')),
                ],
              ),
            )
          else if (error != null) ...[
            Text(error!),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ] else if (result?.observations.isEmpty ?? true)
            const Text(
              'Nenhuma observação com foto disponível neste raio. Isso não significa ausência de fauna. Experimente ampliar o raio.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth >= 640
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final item in result!.observations.take(12))
                      SizedBox(
                        width: width,
                        child: Card(
                          margin: EdgeInsets.zero,
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => showFaunaDetails(context, item),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 72,
                                    height: 72,
                                    child: FaunaPhoto(item: item),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (item.commonName.isNotEmpty)
                                          Text(
                                            item.scientificName,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        Text(
                                          '${item.approximate ? 'Localização aproximada' : 'Aprox. ${item.distanceM?.round() ?? 0} m'} · ${faunaDate(item)}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.attribution,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          const SizedBox(height: 10),
          Text(
            'Até 12 espécies, a partir de uma amostra de até 200 observações recentes com fotos licenciadas. Não é um inventário completo.'
            '${result?.fetchedAt == null ? '' : ' Consulta: ${DateFormat('dd/MM/yyyy HH:mm').format(result!.fetchedAt!.toLocal())}.'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
}

String faunaDate(FaunaObservation item) => item.observedOn == null
    ? 'Data não informada'
    : DateFormat('dd/MM/yyyy').format(item.observedOn!);

class FaunaPhoto extends StatelessWidget {
  final FaunaObservation item;
  const FaunaPhoto({super.key, required this.item});
  @override
  Widget build(BuildContext context) => Image.network(
        item.photoUrl,
        fit: BoxFit.cover,
        semanticLabel: 'Foto de ${item.title}. ${item.attribution}',
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.pets_outlined, size: 36)),
      );
}

Future<void> showFaunaDetails(
  BuildContext context,
  FaunaObservation item,
) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.scientificName,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),
                AspectRatio(aspectRatio: 1.5, child: FaunaPhoto(item: item)),
                const SizedBox(height: 10),
                Text(item.attribution),
                Text('Licença da foto: ${item.license.toUpperCase()}'),
                Text('Observado em ${faunaDate(item)}'),
                if (item.approximate)
                  const Text(
                    'Localização pública aproximada ou obscurecida. O marcador não indica o ponto exato.',
                  ),
                if (item.accuracyM != null)
                  Text(
                    'Precisão informada: aproximadamente ${item.accuracyM!.round()} m',
                  ),
                if (item.distanceM != null && !item.approximate)
                  Text(
                    'Distância aproximada da pista: ${item.distanceM!.round()} m',
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Fonte: iNaturalist. O registro não garante a presença atual da espécie.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          TextButton.icon(
            onPressed: () async {
              final uri = Uri.tryParse(item.url);
              if (uri == null ||
                  uri.scheme != 'https' ||
                  uri.host != 'www.inaturalist.org') {
                return;
              }
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
                  context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Não foi possível abrir o iNaturalist.'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Ver no iNaturalist'),
          ),
        ],
      ),
    );
