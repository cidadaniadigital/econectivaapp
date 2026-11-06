import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:unisinos_usp_app/webclients/econectiva_webclient.dart';

/// The server derives this list from authenticated edit history, never a name match.
class ContributionsPanel extends StatefulWidget {
  const ContributionsPanel({super.key});
  @override
  State<ContributionsPanel> createState() => _ContributionsPanelState();
}

class _ContributionsPanelState extends State<ContributionsPanel> {
  final items = <Map<String, dynamic>>[];
  bool busy = false, more = true;
  String? error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await EconectivaApi().get(
          '/me/contributions', {'limit': '20', 'offset': '${items.length}'});
      if (!mounted) return;
      final page =
          (result as List).map((e) => Map<String, dynamic>.from(e)).toList();
      setState(() {
        items.addAll(page);
        more = page.length == 20;
      });
    } catch (_) {
      if (mounted)
        setState(() => error = 'Não foi possível carregar suas contribuições.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Material(
      child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const Expanded(
                  child: Text('Minhas contribuições',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold))),
              IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close))
            ]),
            const Text(
                'Pistas que você criou ou editou desde o início do registro de alterações.'),
            const SizedBox(height: 20),
            Expanded(
                child: ListView(children: [
              for (final item in items)
                ListTile(
                    leading: const Icon(Icons.edit_note),
                    title: Text(item['name'].toString()),
                    subtitle: Text(
                        'Última contribuição: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(item['last_contribution']).toLocal())}'),
                    onTap: () {
                      Navigator.pop(context);
                      Get.toNamed('/living_clues/show',
                          parameters: {'id': '${item['id']}'});
                    }),
              if (items.isEmpty && !busy && error == null)
                const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                        'Você ainda não tem contribuições registradas. Explore o acervo e participe quando desejar.')),
              if (error != null)
                TextButton(
                    onPressed: _load, child: Text('$error Tentar novamente')),
              if (busy) const Center(child: CircularProgressIndicator()),
              if (more && !busy && error == null && items.isNotEmpty)
                TextButton(
                    onPressed: _load, child: const Text('Carregar mais')),
            ])),
          ])));
}
