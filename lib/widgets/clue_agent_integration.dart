import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/chat_template_model.dart';
import 'package:unisinos_usp_app/models/clue_integration.dart';
import 'package:unisinos_usp_app/webclients/chat_template_webclient.dart';

class ClueAgentSource {
  Future<List<ChatTemplateModel>> search(String query, int offset) =>
      ChatTemplateWebclient().fetch(search: query, offset: offset, limit: 20);
}

Future<void> editClueAgentIntegration(
  BuildContext context,
  QuillController controller, {
  ClueIntegration? initial,
  int? offset,
  ClueAgentSource? source,
}) async {
  final selected = await showDialog<ChatTemplateModel>(
    context: context,
    builder: (_) =>
        ClueAgentPicker(source: source, currentId: initial?.agentId),
  );
  if (selected == null || selected.id <= 0) return;
  final block = ClueIntegration(
    provider: 'agent',
    url: '/chat_templates/chat?id=${selected.id}',
    title: selected.name,
  );
  final at = (offset ?? controller.document.length - 1).clamp(
    0,
    controller.document.length - 1,
  );
  // Attachment selection must not replace author text currently selected in Quill.
  controller.replaceText(
    at,
    offset == null ? 0 : 1,
    BlockEmbed('onlife', block.encode()),
    TextSelection.collapsed(offset: at + 1),
  );
}

class ClueAgentPicker extends StatefulWidget {
  const ClueAgentPicker({super.key, this.source, this.currentId});
  final ClueAgentSource? source;
  final int? currentId;
  @override
  State<ClueAgentPicker> createState() => _ClueAgentPickerState();
}

class _ClueAgentPickerState extends State<ClueAgentPicker> {
  late final source = widget.source ?? ClueAgentSource();
  final search = TextEditingController();
  Timer? debounce;
  int generation = 0;
  int nextOffset = 0;
  List<ChatTemplateModel> agents = [];
  bool loading = true;
  bool moreLoading = false;
  bool hasMore = false;
  bool failed = false;
  bool moreFailed = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    debounce?.cancel();
    search.dispose();
    super.dispose();
  }

  void change(String query) {
    debounce?.cancel();
    generation++;
    setState(() {
      loading = true;
      moreLoading = false;
      failed = false;
      moreFailed = false;
    });
    debounce = Timer(const Duration(milliseconds: 300), load);
  }

  Future<void> load({bool more = false}) async {
    if (more && (loading || moreLoading || !hasMore)) return;
    final request = ++generation;
    final offset = more ? nextOffset : 0;
    setState(() {
      if (more) {
        moreLoading = true;
        moreFailed = false;
      } else {
        loading = true;
        failed = false;
      }
    });
    try {
      final page = await source.search(search.text.trim(), offset);
      if (!mounted || request != generation) return;
      setState(() {
        final merged = more ? [...agents, ...page] : page;
        final seen = <int>{};
        agents = merged.where((a) => a.id > 0 && seen.add(a.id)).toList();
        nextOffset = offset + page.length;
        hasMore = page.length == 20;
        loading = false;
        moreLoading = false;
      });
    } catch (_) {
      if (!mounted || request != generation) return;
      setState(() {
        if (more) {
          moreFailed = true;
        } else {
          failed = true;
        }
        loading = false;
        moreLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.currentId == null
          ? 'Vincular agente à pista'
          : 'Trocar agente da pista',
    ),
    content: SizedBox(
      width: 560,
      height: MediaQuery.sizeOf(context).height * .55,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: search,
            autofocus: true,
            onChanged: change,
            decoration: const InputDecoration(
              labelText: 'Pesquisar agentes',
              hintText: 'Nome ou descrição',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Selecione um agente para vincular à pista.'),
          const SizedBox(height: 12),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : failed
                ? Center(
                    child: TextButton.icon(
                      onPressed: load,
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        'Não foi possível carregar. Tentar novamente',
                      ),
                    ),
                  )
                : agents.isEmpty
                ? const Center(
                    child: Text('Nenhum agente encontrado para esta pesquisa.'),
                  )
                : ListView.builder(
                    itemCount: agents.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == agents.length) {
                        return moreLoading
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : TextButton(
                                onPressed: () => load(more: true),
                                child: Text(
                                  moreFailed
                                      ? 'Tentar carregar mais agentes'
                                      : 'Carregar mais agentes',
                                ),
                              );
                      }
                      final agent = agents[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.psychology_outlined,
                          color: Color(0xFF9CE7DF),
                        ),
                        title: Text(
                          agent.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: agent.description?.trim().isNotEmpty == true
                            ? Text(
                                agent.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: Icon(
                          agent.id == widget.currentId
                              ? Icons.check_circle_outline
                              : Icons.add_link,
                        ),
                        onTap: () => Navigator.of(context).pop(agent),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
    ],
  );
}

class ClueAgentIntegrationCard extends StatelessWidget {
  const ClueAgentIntegrationCard({
    super.key,
    required this.block,
    this.editing = false,
    this.onEdit,
    this.onRemove,
  });
  final ClueIntegration block;
  final bool editing;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_outlined, color: Color(0xFF9CE7DF)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    block.title.isEmpty ? 'Agente da plataforma' : block.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              editing
                  ? 'Agente vinculado à pista'
                  : 'Converse com este agente da Educação OnLIFE.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: editing
                  ? [
                      OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.sync),
                        label: const Text('Trocar agente'),
                      ),
                      TextButton.icon(
                        onPressed: onRemove,
                        icon: const Icon(Icons.link_off),
                        label: const Text('Desvincular agente'),
                      ),
                    ]
                  : [
                      OutlinedButton.icon(
                        onPressed: block.agentId == null
                            ? null
                            : () => Get.toNamed(
                                '/chat_templates/chat',
                                parameters: {'id': '${block.agentId}'}, arguments: {'from_clue': true},
                              ),
                        icon: const Icon(Icons.forum_outlined),
                        label: const Text('Conectar-se ao agente'),
                      ),
                    ],
            ),
          ],
        ),
      ),
    ),
  );
}

class ClueAgentCards extends StatelessWidget {
  const ClueAgentCards({super.key, required this.controller, this.source});
  final QuillController controller;
  final ClueAgentSource? source;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      var offset = 0;
      final cards = <Widget>[];
      for (final op in controller.document.toDelta().toJson()) {
        final insert = op['insert'];
        final at = offset;
        offset += insert is String ? insert.length : 1;
        if (insert is! Map || !insert.containsKey('onlife')) continue;
        final block = ClueIntegration.decode(insert['onlife']);
        if (block == null || !block.supported || block.agentId == null)
          continue;
        cards.add(
          ClueAgentIntegrationCard(
            block: block,
            editing: true,
            onEdit: () => editClueAgentIntegration(
              context,
              controller,
              initial: block,
              offset: at,
              source: source,
            ),
            onRemove: () => controller.replaceText(
              at,
              1,
              '',
              TextSelection.collapsed(offset: at),
            ),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: cards,
      );
    },
  );
}
