import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/webclients/econectiva_webclient.dart';

String eventDate(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  return date == null
      ? ''
      : DateFormat('dd/MM/yyyy • HH:mm').format(date.toLocal());
}

class ClueParticipation extends StatefulWidget {
  const ClueParticipation({super.key, required this.clueId});
  final int clueId;
  @override
  State<ClueParticipation> createState() => _ClueParticipationState();
}

class _ClueParticipationState extends State<ClueParticipation> {
  final api = EconectivaApi();
  final text = TextEditingController();
  List<dynamic> roots = [];
  final replies = <int, List<dynamic>>{};
  final replyMore = <int, bool>{};
  bool loading = true;
  bool sending = false;
  bool more = true;
  String? error;
  Map<String, dynamic>? replyTo;
  Map<String, dynamic>? editing;
  String get path => '/living_clues/${widget.clueId}/comments';
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> load({bool next = false}) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await api.get(path, {
        'limit': '20',
        'offset': next ? roots.length.toString() : '0',
      });
      if (!mounted) return;
      setState(() {
        if (!next) {
          roots = [];
          replies.clear();
          replyMore.clear();
        }
        roots.addAll(data as List);
        more = data.length == 20;
      });
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Não foi possível carregar as Comentários.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> loadReplies(int root, {bool next = false}) async {
    try {
      final data = await api.get(path, {
        'root_id': '$root',
        'limit': '20',
        'offset': next ? '${replies[root]?.length ?? 0}' : '0',
      });
      if (!mounted) return;
      setState(() {
        replies[root] = [if (next) ...?replies[root], ...(data as List)];
        replyMore[root] = data.length == 20;
      });
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Não foi possível carregar as respostas.');
      }
    }
  }

  Future<void> send() async {
    if (text.text.trim().isEmpty || sending) return;
    if (text.text.runes.length > 5000) {
      setState(
        () => error = 'Escreva uma mensagem de até 5000 caracteres Unicode.',
      );
      return;
    }
    setState(() => sending = true);
    try {
      final edit = editing;
      final thread =
          editing?['root_id'] ?? replyTo?['root_id'] ?? replyTo?['id'];
      await api.write(
        edit == null ? 'POST' : 'PUT',
        edit == null ? path : '$path/${edit['id']}',
        {
          'content': text.text,
          if (replyTo != null) 'reply_to_id': replyTo!['id'],
        },
      );
      if (!mounted) return;
      text.clear();
      setState(() {
        editing = null;
        replyTo = null;
      });
      await load();
      if (thread != null && mounted) await loadReplies(thread);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Não foi possível publicar. Seu texto foi preservado.',
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> remove(Map<String, dynamic> m) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir sua mensagem?'),
        content: const Text(
          'As respostas de outras pessoas serão preservadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await api.write('DELETE', '$path/${m['id']}');
      await load();
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Não foi possível excluir a mensagem.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.forum_outlined),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Comentários',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Atualizar conversa',
                onPressed: loading ? null : () => load(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Converse com quem também está descobrindo esta pista.'),
          const SizedBox(height: 16),
          if (replyTo != null || editing != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    editing != null
                        ? 'Editando sua mensagem'
                        : 'Respondendo a ${replyTo!['author']['name']}',
                  ),
                ),
                IconButton(
                  tooltip: 'Cancelar',
                  onPressed: () => setState(() {
                    editing = null;
                    replyTo = null;
                    text.clear();
                  }),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          TextField(
            controller: text,
            minLines: 2,
            maxLines: 6,
            maxLength: 5000,
            decoration: const InputDecoration(
              hintText:
                  'Compartilhe uma ideia, uma pergunta ou uma descoberta…',
              border: OutlineInputBorder(),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: sending ? null : send,
              icon: const Icon(Icons.send_outlined, size: 18),
              label: Text(
                sending
                    ? 'Publicando…'
                    : editing != null
                    ? 'Salvar edição'
                    : 'Compartilhar',
              ),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                error!,
                style: const TextStyle(color: Colors.deepOrange),
              ),
            ),
          if (loading) const LinearProgressIndicator(),
          if (!loading && roots.isEmpty && error == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Esta conversa começa com você. ✨'),
            ),
          for (final raw in roots) ...[
            message(Map<String, dynamic>.from(raw)),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final reply in replies[raw['id']] ?? [])
                    message(Map<String, dynamic>.from(reply)),
                  TextButton.icon(
                    onPressed: () => loadReplies(
                      raw['id'],
                      next: replyMore[raw['id']] ?? false,
                    ),
                    icon: const Icon(Icons.subdirectory_arrow_right, size: 18),
                    label: Text(
                      !replies.containsKey(raw['id'])
                          ? 'Ver respostas'
                          : replyMore[raw['id']] ?? false
                          ? 'Mais respostas'
                          : 'Atualizar respostas',
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
          ],
          if (more && roots.isNotEmpty)
            TextButton(
              onPressed: loading ? null : () => load(next: true),
              child: const Text('Carregar mais comentários'),
            ),
        ],
      ),
    ),
  );
  Widget message(Map<String, dynamic> m) {
    final own = m['user_id'] == Get.find<UserController>().user.value?.id;
    final removed = m['removed_at'] != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CircleAvatar(
                radius: 15,
                child: Text(
                  (m['author']?['name'] ?? '?').toString().characters.first,
                ),
              ),
              Text(
                m['author']?['name'] ?? 'Participante',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                '${eventDate(m['created_at'])}${m['edited_at'] != null ? ' • editado' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (m['reply_to_id'] != null)
            Text(
              m['reply_to_author']?['name'] != null
                  ? 'Em resposta a ${m['reply_to_author']['name']}'
                  : 'Em resposta à mensagem #${m['reply_to_id']}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          SelectableText(removed ? 'Comentário excluído' : m['content']),
          if (!removed)
            Wrap(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      replyTo = m;
                      editing = null;
                    });
                  },
                  child: const Text('Responder'),
                ),
                if (own) ...[
                  TextButton(
                    onPressed: () => setState(() {
                      editing = m;
                      replyTo = null;
                      text.text = m['content'];
                    }),
                    child: const Text('Editar'),
                  ),
                  TextButton(
                    onPressed: () => remove(m),
                    child: const Text('Excluir'),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class ClueEditHistory extends StatefulWidget {
  const ClueEditHistory({super.key, required this.clueId});
  final int clueId;
  @override
  State<ClueEditHistory> createState() => _ClueEditHistoryState();
}

class _ClueEditHistoryState extends State<ClueEditHistory> {
  List<dynamic> events = [];
  bool loading = false;
  bool more = true;
  String? error;
  Future<void> load() async {
    if (loading) return;
    setState(() => loading = true);
    try {
      final data = await EconectivaApi().get(
        '/living_clues/${widget.clueId}/edits',
        {'limit': '20', 'offset': '${events.length}'},
      );
      if (mounted) {
        setState(() {
          events.addAll(data as List);
          more = data.length == 20;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => error = 'Histórico indisponível.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      leading: const Icon(Icons.history),
      title: const Text('Histórico de edições'),
      onExpansionChanged: (open) {
        if (open && events.isEmpty) load();
      },
      children: [
        if (loading) const LinearProgressIndicator(),
        if (error != null) Text(error!),
        if (!loading && events.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Nenhuma edição registrada após a atualização.'),
          ),
        for (final e in events)
          ListTile(
            title: Text('${e['author']['name']} • Pista editada'),
            subtitle: Text(eventDate(e['created_at'])),
          ),
        if (more && events.isNotEmpty || error != null)
          TextButton(onPressed: load, child: const Text('Carregar histórico')),
      ],
    ),
  );
}
