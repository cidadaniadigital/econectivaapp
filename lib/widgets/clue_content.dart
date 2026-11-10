import 'dart:convert';
import 'package:unisinos_usp_app/widgets/cdig_source.dart';
import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ClueContent extends StatelessWidget {
  const ClueContent({super.key, required this.clue});
  final LivingClueModel clue;
  static List<Uri> links(LivingClueModel clue) {
    final candidates = <String>[
      ...RegExp(r'https?://[^\s<>"\x27]+')
          .allMatches(clue.description ?? '')
          .map((m) => m.group(0)!),
      for (final key in ['url', 'source_url', 'link', 'conteudo_url'])
        if (clue.metadata?[key] is String) clue.metadata![key],
    ];
    return candidates
        .map((s) => Uri.tryParse(s.replaceFirst(RegExp(r'[.,;)]$'), '')))
        .whereType<Uri>()
        .where((uri) =>
            {'https', 'http'}.contains(uri.scheme) && uri.host.isNotEmpty)
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final source = clue.metadata?['cdig'];
    final sourceUrl =
        source is Map ? Uri.tryParse('${source['url'] ?? ''}') : null;
    final urls = links(clue).where((uri) => uri != sourceUrl).toList();
    final attributes = (clue.metadata ?? {})
        .entries
        .where((e) => !{
              'cdig',
              'imagem_capa_arquivo_id',
              'capa_automatica_desativada',
              'imagem_capa_ajuste',
              'colecao_ordem_itens_v1',
              'destaque_catalogo',
              'destaque_inicio_ordem',
              'url',
              'source_url',
              'link',
              'conteudo_url',
              if (source is Map) ...{
                'acervo',
                'fonte',
                'recurso_original',
                'identificador_origem',
                'lote_importacao',
              }
            }.contains(e.key))
        .toList();
    if (urls.isEmpty && attributes.isEmpty) return CdigSource(clue: clue);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      CdigSource(clue: clue),
      Card(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (attributes.isNotEmpty) ...[
                      Text('Características cadastradas',
                          style: Theme.of(context).textTheme.titleLarge),
                      const Text(
                          'Informações declaradas no cadastro desta pista.'),
                      ...attributes.map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                              '${e.key.replaceAll('_', ' ')}: ${e.value is Map || e.value is List ? jsonEncode(e.value) : e.value ?? 'não informado'}'))),
                    ],
                    if (urls.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Conteúdo e referências vinculadas',
                          style: Theme.of(context).textTheme.titleLarge),
                      ...urls.map((uri) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.open_in_new),
                          title: Text(uri.host),
                          subtitle: Text(uri.toString()),
                          onTap: () async {
                            final opened = await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                            if (!opened && context.mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Não foi possível abrir o conteúdo.')));
                          })),
                    ],
                  ]))),
    ]);
  }
}
