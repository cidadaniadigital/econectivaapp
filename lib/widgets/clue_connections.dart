import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/webclients/clue_connection_webclient.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/services/collection_service.dart';

class ClueConnections extends StatefulWidget {
  const ClueConnections(
      {super.key, required this.clueId, this.canEdit = false});
  final int clueId;
  final bool canEdit;
  @override
  State<ClueConnections> createState() => _ClueConnectionsState();
}

class _ClueConnectionsState extends State<ClueConnections> {
  late Future<List<Map<String, dynamic>>> _links;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _links = CollectionService().connections(widget.clueId);
  }

  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Conexões', style: Theme.of(context).textTheme.titleLarge),
            const Text('As setas mostram a direção da relação cadastrada.'),
            if (widget.canEdit)
              Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                      icon: const Icon(Icons.add_link),
                      label: const Text('Nova conexão'),
                      onPressed: () async {
                        try {
                          final clue = await CollectionService()
                              .clues
                              .fetchById(widget.clueId);
                          if (!mounted) return;
                          await Get.toNamed('/living_clues/connect',
                              arguments: clue);
                          if (mounted) setState(_reload);
                        } catch (_) {
                          if (mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Não foi possível abrir a conexão. Tente novamente.')));
                        }
                      })),
            FutureBuilder<List<Map<String, dynamic>>>(
                future: _links,
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return TextButton(
                        onPressed: () => setState(_reload),
                        child: const Text(
                            'Falha ao consultar conexões. Tentar novamente'));
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  if (snapshot.data!.isEmpty)
                    return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Nenhuma conexão cadastrada.'));
                  return Column(
                      children: snapshot.data!.map((link) {
                    final outgoing = link['source_clue_id'] == widget.clueId;
                    final related =
                        link[outgoing ? 'target_clue' : 'source_clue'];
                    final type = link['connection_type'];
                    final relation = type is Map
                        ? type['name']?.toString() ?? 'Relação'
                        : 'Relação';
                    final directional =
                        type is Map && type['is_directional'] == true;
                    final clue = related is Map
                        ? LivingClueModel.fromJson(
                            Map<String, dynamic>.from(related))
                        : null;
                    return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(directional
                            ? (outgoing
                                ? Icons.arrow_forward
                                : Icons.arrow_back)
                            : Icons.swap_horiz),
                        title: Text(clue?.name ?? 'Pista indisponível'),
                        subtitle: Text(
                            '$relation${link['strength'] == null ? '' : ' • Força: ${link['strength']}'}${link['evidence'] == null || link['evidence'] == '' ? '' : '\nEvidência: ${link['evidence']}'}${directional ? outgoing ? ' • desta pista para o destino' : ' • da origem para esta pista' : ' • sem direção'}'),
                        trailing: widget.canEdit
                            ? PopupMenuButton<String>(
                                tooltip: 'Gerenciar conexão',
                                onSelected: (action) async {
                                  if (action == 'edit') {
                                    await Get.toNamed(
                                        '/clue_connections/update',
                                        parameters: {'id': '${link['id']}'});
                                  } else {
                                    final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                                title: const Text(
                                                    'Remover conexão?'),
                                                content: const Text(
                                                    'As pistas serão preservadas.'),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, false),
                                                      child: const Text(
                                                          'Cancelar')),
                                                  FilledButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true),
                                                      child:
                                                          const Text('Remover'))
                                                ]));
                                    if (confirmed != true || !mounted) return;
                                    try {
                                      await ClueConnectionWebclient()
                                          .delete(link['id']);
                                    } catch (_) {
                                      if (mounted)
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    'Não foi possível remover. Tente novamente.')));
                                    }
                                  }
                                  if (mounted) setState(_reload);
                                },
                                itemBuilder: (_) => const [
                                      PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Editar conexão')),
                                      PopupMenuItem(
                                          value: 'remove',
                                          child: Text('Remover conexão')),
                                    ])
                            : clue == null
                                ? null
                                : const Icon(Icons.chevron_right),
                        onTap: clue == null
                            ? null
                            : () => Get.toNamed(
                                CollectionService.isCollection(clue)
                                    ? '/collections/show'
                                    : '/living_clues/show',
                                parameters: {'id': '${clue.id}'}));
                  }).toList());
                }),
          ])));
}
