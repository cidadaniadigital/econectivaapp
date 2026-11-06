import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:unisinos_usp_app/services/locker_service.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';

class LockerButton extends StatelessWidget {
  const LockerButton({super.key, required this.type, required this.id});
  final String type;
  final int id;
  @override
  Widget build(BuildContext context) {
    final s = Get.find<LockerService>();
    return Obx(() => IconButton(
        tooltip: s.saved(type, id)
            ? 'Remover dos itens salvos'
            : 'Salvar nos itens salvos',
        onPressed:
            s.busy.contains('$type:$id') ? null : () => s.toggle(type, id),
        icon:
            Icon(s.saved(type, id) ? Icons.bookmark : Icons.bookmark_border)));
  }
}

class LockerPanel extends StatefulWidget {
  const LockerPanel({super.key});
  @override
  State<LockerPanel> createState() => _LockerPanelState();
}

class _LockerPanelState extends State<LockerPanel> {
  final service = Get.find<LockerService>();
  String search = '';
  String type = 'all';
  @override
  void initState() {
    super.initState();
    service.load();
  }

  @override
  Widget build(BuildContext context) => Material(
      color: const Color(0xFF101A30),
      borderRadius: BorderRadius.circular(24),
      child: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.bookmarks_outlined,
                          color: Color(0xFF65DFD2)),
                      const SizedBox(width: 12),
                      const Expanded(
                          child: Text('Seus itens salvos',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white))),
                      IconButton(
                          tooltip: 'Fechar itens salvos',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white))
                    ]),
                    const Text(
                        'Reúna pistas, grafos e agentes para consultar depois.',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 20),
                    TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                            hintText: 'Buscar por nome',
                            hintStyle: TextStyle(color: Colors.white60),
                            prefixIcon:
                                Icon(Icons.search, color: Colors.white60)),
                        onChanged: (v) => setState(() => search = v)),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, children: [
                      for (final e in {
                        'all': 'Tudo',
                        'living_clue': 'Pistas',
                        'node': 'Grafos',
                        'agent': 'Agentes'
                      }.entries)
                        ChoiceChip(
                            label: Text(e.value),
                            selected: type == e.key,
                            onSelected: (_) => setState(() => type = e.key))
                    ]),
                    const SizedBox(height: 12),
                    Expanded(child: Obx(() {
                      if (service.loading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (service.error.value != null) {
                        return Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              Text(service.error.value!,
                                  style:
                                      const TextStyle(color: Colors.white70)),
                              TextButton(
                                  onPressed: service.load,
                                  child: const Text('Tentar novamente'))
                            ]));
                      }
                      final list = service.items
                          .where((e) =>
                              (type == 'all' || type == e['entity_type']) &&
                              e['name']
                                  .toString()
                                  .toLowerCase()
                                  .contains(search.toLowerCase()))
                          .toList();
                      if (list.isEmpty) {
                        return const Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              Icon(Icons.bookmark_add_outlined,
                                  size: 48, color: Color(0xFF65DFD2)),
                              SizedBox(height: 16),
                              Text('Guarde suas próximas descobertas',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 18)),
                              SizedBox(height: 8),
                              Text(
                                  'Use o marcador nas pistas, grafos e agentes.\nSuas referências ficam reunidas aqui.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white60))
                            ]));
                      }
                      return ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final e = list[i];
                            return ListTile(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                tileColor: Colors.white.withValues(alpha: .05),
                                leading: Icon(
                                    e['entity_type'] == 'node'
                                        ? Icons.hub_outlined
                                        : Icons.radar,
                                    color: const Color(0xFF65DFD2)),
                                title: Text(e['name'],
                                    style:
                                        const TextStyle(color: Colors.white)),
                                subtitle: Text(
                                    '${e['origin'] ?? ''} • ${DateFormat('dd/MM/yyyy').format(DateTime.parse(e['created_at']).toLocal())}',
                                    style:
                                        const TextStyle(color: Colors.white60)),
                                trailing: LockerButton(
                                    type: e['entity_type'], id: e['entity_id']),
                                onTap: e['available'] != true
                                    ? null
                                    : () async {
                                        try {
                                          if (e['entity_type'] ==
                                              'living_clue') {
                                            final clue =
                                                await LivingClueWebclient()
                                                    .fetchById(e['entity_id']);
                                            if (!context.mounted) return;
                                            Navigator.pop(context);
                                            Get.toNamed('/living_clues/show',
                                                arguments: clue);
                                          } else if (e['entity_type'] ==
                                              'agent') {
                                            Navigator.pop(context);
                                            Get.toNamed('/chat_templates/chat',
                                                parameters: {
                                                  'id':
                                                      e['entity_id'].toString()
                                                });
                                          } else {
                                            Navigator.pop(context);
                                            Get.toNamed('/nodes/graph',
                                                parameters: {
                                                  'focus':
                                                      e['entity_id'].toString()
                                                });
                                          }
                                        } catch (_) {
                                          Get.snackbar('Itens salvos',
                                              'Conteúdo indisponível.');
                                        }
                                      });
                          });
                    })),
                  ]))));
}
