import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/services/collection_service.dart';
import 'package:unisinos_usp_app/models/category_model.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/webclients/category_webclient.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';
import 'package:unisinos_usp_app/widgets/clue_cover.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _search = TextEditingController();
  final _client = LivingClueWebclient();
  List<LivingClueModel> _items = [];
  List<CategoryModel> _categories = [];
  int? _category;
  bool _busy = false, _more = true;
  String? _error;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _search.text = Get.parameters['search'] ?? '';
    _category = int.tryParse(Get.parameters['category'] ?? '');
    _load(reset: true);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CategoryWebclient().fetch();
      if (mounted) setState(() => _categories = categories);
    } catch (_) {/* Search remains available without category catalog. */}
  }

  Future<void> _load({bool reset = false}) async {
    if (_busy && !reset) return;
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _error = null;
      if (reset) {
        _items = [];
        _more = true;
      }
    });
    try {
      final items = await _client.fetch(
          search: _search.text.trim(),
          categoryId: _category,
          offset: reset ? 0 : _items.length,
          limit: 24);
      if (mounted && generation == _generation)
        setState(() {
          _items.addAll(items);
          _more = items.length == 24;
        });
    } catch (_) {
      if (mounted && generation == _generation)
        setState(() => _error = 'Não foi possível carregar o catálogo.');
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          leading: const SafeBackButton(),
          title: const Text('Explorar o acervo'),
          actions: [
            IconButton(
                tooltip: 'Nova coleção',
                icon: const Icon(Icons.library_add_outlined),
                onPressed: () => Get.toNamed('/collections/create')),
            IconButton(
                tooltip: 'Mapa',
                icon: const Icon(Icons.map_outlined),
                onPressed: () => Get.toNamed('/living_clues/map'))
          ]),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Pistas, pesquisas e conteúdos',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const Text(
                            'Explore o acervo e suas conexões. Registros sem localização também aparecem aqui.'),
                        const SizedBox(height: 20),
                        TextField(
                            controller: _search,
                            onSubmitted: (_) => _load(reset: true),
                            decoration: InputDecoration(
                                labelText: 'Buscar por título ou descrição',
                                suffixIcon: IconButton(
                                    tooltip: 'Buscar',
                                    icon: const Icon(Icons.search),
                                    onPressed: () => _load(reset: true)))),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                            initialValue: _category,
                            isExpanded: true,
                            decoration:
                                const InputDecoration(labelText: 'Categoria'),
                            items: [
                              if (_category != null &&
                                  !_categories.any((c) => c.id == _category))
                                DropdownMenuItem<int>(
                                    value: _category,
                                    child: Text('Categoria $_category')),
                              const DropdownMenuItem<int>(
                                  value: null,
                                  child: Text('Todas as categorias')),
                              ..._categories.map((c) => DropdownMenuItem(
                                  value: c.id, child: Text(c.name)))
                            ],
                            onChanged: (value) {
                              _category = value;
                              _load(reset: true);
                            }),
                        const SizedBox(height: 20),
                        if (_items.isEmpty && !_busy && _error == null)
                          const Text('Nenhum registro encontrado.'),
                        LayoutBuilder(builder: (context, bounds) {
                          final columns = bounds.maxWidth < 550
                              ? 1
                              : bounds.maxWidth < 900
                                  ? 2
                                  : 3;
                          final width =
                              (bounds.maxWidth - (columns - 1) * 16) / columns;
                          return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: _items
                                  .map((item) => SizedBox(
                                      width: width,
                                      child: Card(
                                          clipBehavior: Clip.antiAlias,
                                          child: InkWell(
                                              onTap: () =>
                                                  Get.toNamed(
                                                      CollectionService
                                                              .isCollection(
                                                                  item)
                                                          ? '/collections/show'
                                                          : '/living_clues/show',
                                                      parameters: {
                                                        'id': '${item.id}'
                                                      }),
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    ClueCover(
                                                        clue: item,
                                                        height: 160),
                                                    Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(16),
                                                        child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(item.name,
                                                                  maxLines: 2,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .titleMedium),
                                                              Text(item.category
                                                                      ?.name ??
                                                                  'Categoria ${item.categoryId}'),
                                                              if ((item.description ??
                                                                      '')
                                                                  .isNotEmpty)
                                                                Text(
                                                                    item
                                                                        .description!,
                                                                    maxLines: 3,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis),
                                                            ])),
                                                  ])))))
                                  .toList());
                        }),
                        if (_busy)
                          const Padding(
                              padding: EdgeInsets.all(20),
                              child:
                                  Center(child: CircularProgressIndicator())),
                        if (_error != null)
                          TextButton(
                              onPressed: () => _load(reset: _items.isEmpty),
                              child: Text('$_error Tentar novamente')),
                        if (_more && !_busy && _error == null)
                          Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: OutlinedButton(
                                  onPressed: _load,
                                  child: const Text('Carregar mais'))),
                      ])))));
}
