import 'package:unisinos_usp_app/widgets/contributions_panel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/services/collection_service.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';
import 'package:unisinos_usp_app/webclients/preferences_webclient.dart';
import 'package:unisinos_usp_app/widgets/discovery_content.dart';
import 'package:unisinos_usp_app/widgets/locker_panel.dart';

class CatalogHomeScreen extends StatefulWidget {
  const CatalogHomeScreen({super.key});
  @override
  State<CatalogHomeScreen> createState() => _CatalogHomeScreenState();
}

class _CatalogHomeScreenState extends State<CatalogHomeScreen> {
  late Future<List<LivingClueModel>> _data;
  final _search = TextEditingController();
  bool _canEdit = false;
  @override
  void initState() {
    super.initState();
    _data = _load();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    try {
      final enabled = await PreferencesWebclient().editingEnabled();
      if (mounted) setState(() => _canEdit = enabled);
    } catch (_) {}
  }

  Future<List<LivingClueModel>> _load() async {
    final all = <LivingClueModel>[];
    while (true) {
      final page =
          await LivingClueWebclient().fetch(limit: 100, offset: all.length);
      all.addAll(page);
      if (page.length < 100) return all;
    }
  }

  Future<void> _navigate(String route,
      {Map<String, String>? parameters}) async {
    await Get.toNamed(route, parameters: parameters);
    if (mounted) {
      setState(() => _data = _load());
      _loadPermissions();
    }
  }

  void _open(LivingClueModel clue) => _navigate(
      CollectionService.isCollection(clue)
          ? '/collections/show'
          : '/living_clues/show',
      parameters: {'id': '${clue.id}'});
  void _saved() => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          const FractionallySizedBox(heightFactor: .9, child: LockerPanel()));
  void _contributions() => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const FractionallySizedBox(
          heightFactor: .9, child: ContributionsPanel()));
  void _find() =>
      _navigate('/catalog', parameters: {'search': _search.text.trim()});
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('ATOPOS'), actions: [
        IconButton(
            tooltip: 'Itens salvos',
            onPressed: _saved,
            icon: const Icon(Icons.bookmarks_outlined)),
        IconButton(
            tooltip: 'Mapa',
            onPressed: () => _navigate('/living_clues/map'),
            icon: const Icon(Icons.map_outlined)),
        PopupMenuButton<String>(
            tooltip: 'Menu',
            onSelected: (value) async {
              if (value == 'logout') {
                await Get.find<UserController>().logout();
              } else if (value == 'saved') {
                _saved();
              } else {
                await _navigate(value);
              }
            },
            itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: '/catalog', child: Text('Pesquisar acervo')),
                  const PopupMenuItem(
                      value: 'saved', child: Text('Itens salvos')),
                  if (_canEdit)
                    const PopupMenuItem(
                        value: '/collections/create',
                        child: Text('Nova coleção')),
                  const PopupMenuItem(
                      value: '/management',
                      child: Text('Cadastros e ferramentas')),
                  const PopupMenuItem(
                      value: '/profile', child: Text('Meu perfil')),
                  const PopupMenuItem(value: 'logout', child: Text('Sair')),
                ]),
      ]),
      body: FutureBuilder<List<LivingClueModel>>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return Center(
                  child: TextButton(
                      onPressed: () => setState(() => _data = _load()),
                      child: const Text(
                          'Falha ao carregar acervo. Tentar novamente')));
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            return Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child:
                        ListView(padding: const EdgeInsets.all(20), children: [
                      DiscoveryContent(
                          items: snapshot.data!,
                          search: _search,
                          onSearch: _find,
                          onCatalog: () => _navigate('/catalog'),
                          onMap: () => _navigate('/living_clues/map'),
                          onCategory: (id) => _navigate('/catalog',
                              parameters: {'category': '$id'}),
                          onOpen: _open,
                          personal:
                              Wrap(spacing: 12, runSpacing: 12, children: [
                            OutlinedButton.icon(
                                onPressed: _saved,
                                icon: const Icon(Icons.bookmarks_outlined),
                                label: const Text('Meus itens salvos')),
                            OutlinedButton.icon(
                                onPressed: () => _navigate('/profile'),
                                icon: const Icon(Icons.person_outline),
                                label: const Text('Meu perfil')),
                            OutlinedButton.icon(
                                onPressed: _contributions,
                                icon: const Icon(Icons.edit_note),
                                label: const Text('Minhas contribuições')),
                            if (_canEdit)
                              FilledButton.icon(
                                  onPressed: () =>
                                      _navigate('/living_clues/create'),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Criar pista')),
                          ])),
                    ])));
          }));
}
