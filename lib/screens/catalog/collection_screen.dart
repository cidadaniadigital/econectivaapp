import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/widgets/rich_clue_editor.dart';
import 'package:unisinos_usp_app/widgets/living_clue_description_view.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/services/collection_service.dart';
import 'package:unisinos_usp_app/webclients/preferences_webclient.dart';
import 'package:unisinos_usp_app/widgets/clue_cover.dart';
import 'package:unisinos_usp_app/widgets/clue_cover_editor.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});
  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final _service = CollectionService();
  final _name = TextEditingController(), _description = TextEditingController();
  final _cover = CoverSelection();
  String? _delta;
  bool _featured = false;
  LivingClueModel? _collection;
  List<LivingClueModel> _items = [];
  bool _busy = true, _canEdit = false, _editing = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = int.tryParse(Get.parameters['id'] ?? '');
      _canEdit = await PreferencesWebclient().editingEnabled();
      if (id != null) {
        final collection = await _service.clues.fetchById(id);
        if (!CollectionService.isCollection(collection))
          throw StateError('A pista não é uma coleção temática.');
        _collection = collection;
        _featured = collection.metadata?['destaque_catalogo'] == true;
        _delta = collection.descriptionDelta;
        _name.text = collection.name;
        _description.text = collection.description ?? '';
        _items = await _service.items(collection);
      } else {
        if (!_canEdit)
          throw StateError(
              'Ative criação e edição no perfil para criar coleções.');
        _editing = true;
      }
    } catch (e) {
      _error = 'Não foi possível abrir a coleção. $e';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy || !_canEdit) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await operation();
    } catch (e) {
      _error = 'Não foi possível concluir. $e';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() => _run(() async {
        if (_name.text.trim().isEmpty) throw StateError('Informe o título.');
        var collection = _collection;
        if (collection == null) {
          final category = (await _service.category(create: true))!;
          collection = await _service.clues.create(LivingClueModel(
              id: 0,
              name: _name.text.trim(),
              categoryId: category.id,
              description: _description.text.trim(),
              descriptionDelta: _delta));
          _collection =
              collection; // A retry cannot duplicate the newly created clue.
        } else {
          collection = await _service.clues.fetchById(collection.id);
          collection.name = _name.text.trim();
          collection.description = _description.text.trim();
          collection.descriptionDelta = _delta;
        }
        collection.metadata = {
          ...?collection.metadata,
          'destaque_catalogo': _featured
        };
        await _cover.apply(collection);
        _collection = await _service.clues.update(collection);
        _editing = false;
        if (Get.parameters['id'] != '${_collection!.id}') {
          Get.offNamed('/collections/show',
              parameters: {'id': '${_collection!.id}'});
        }
      });
  Future<void> _pickItem() async {
    final chosen = await showDialog<LivingClueModel>(
        context: context,
        builder: (_) => _ItemPicker(
            service: _service,
            excluded: {_collection!.id, ..._items.map((i) => i.id)}));
    if (chosen == null || !mounted) return;
    await _run(() async {
      await _service.add(_collection!, chosen.id);
      _collection = await _service.clues.fetchById(_collection!.id);
      _items = await _service.items(_collection!);
      _collection = await _service.saveOrder(
          _collection!.id, _items.map((i) => i.id).toList());
    });
  }

  Future<void> _move(int index, int delta) => _run(() async {
        final target = index + delta;
        if (target < 0 || target >= _items.length) return;
        final reordered = [..._items];
        final item = reordered.removeAt(index);
        reordered.insert(target, item);
        _collection = await _service.saveOrder(
            _collection!.id, reordered.map((i) => i.id).toList());
        _items = reordered;
      });
  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _cover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          leading: const SafeBackButton(),
          title: const Text('Coleção temática'),
          actions: [
            if (_collection != null && _canEdit && !_editing)
              IconButton(
                  tooltip: 'Editar coleção',
                  onPressed:
                      _busy ? null : () => setState(() => _editing = true),
                  icon: const Icon(Icons.edit_outlined))
          ]),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_busy) const LinearProgressIndicator(),
                        if (_error != null)
                          Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(_error!)),
                        if (_editing && _canEdit) ...[
                          TextField(
                              controller: _name,
                              decoration: const InputDecoration(
                                  labelText: 'Título da coleção')),
                          const SizedBox(height: 12),
                          RichClueEditor(
                              plainText: _description.text,
                              delta: _delta,
                              onChanged: (text, delta) {
                                _description.text = text;
                                _delta = delta;
                              }),
                          const SizedBox(height: 12),
                          ClueCoverEditor(selection: _cover),
                          SwitchListTile(
                              title: const Text('Destacar no catálogo'),
                              subtitle: const Text(
                                  'Seleção editorial explícita para a home.'),
                              value: _featured,
                              onChanged: _busy
                                  ? null
                                  : (value) =>
                                      setState(() => _featured = value)),
                          FilledButton(
                              onPressed: _busy ? null : _save,
                              child: const Text('Salvar coleção')),
                        ] else if (_collection != null) ...[
                          ClueCover(
                              clue: _collection!, collectionItems: _items),
                          const SizedBox(height: 20),
                          Text(_collection!.name,
                              style:
                                  Theme.of(context).textTheme.headlineMedium),
                          LivingClueDescriptionView(
                              plainText: _collection!.description ?? '',
                              delta: _collection!.descriptionDelta,
                              clueId: _collection!.id),
                          const SizedBox(height: 20),
                        ],
                        if (_collection != null) ...[
                          const Text('Itens da coleção',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          if (_canEdit)
                            OutlinedButton.icon(
                                onPressed: _busy ? null : _pickItem,
                                icon: const Icon(Icons.add),
                                label:
                                    const Text('Adicionar registro existente')),
                          if (_items.isEmpty && !_busy)
                            const Text('Esta coleção ainda não tem itens.'),
                          ..._items.asMap().entries.map((entry) => Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(children: [
                                    ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(entry.value.name),
                                        subtitle: Text(
                                            entry.value.category?.name ?? ''),
                                        onTap: () => Get.toNamed(
                                                CollectionService.isCollection(
                                                        entry.value)
                                                    ? '/collections/show'
                                                    : '/living_clues/show',
                                                parameters: {
                                                  'id': '${entry.value.id}'
                                                })),
                                    if (_canEdit)
                                      Wrap(children: [
                                        IconButton(
                                            tooltip: 'Mover para cima',
                                            onPressed: _busy || entry.key == 0
                                                ? null
                                                : () => _move(entry.key, -1),
                                            icon:
                                                const Icon(Icons.arrow_upward)),
                                        IconButton(
                                            tooltip: 'Mover para baixo',
                                            onPressed: _busy ||
                                                    entry.key ==
                                                        _items.length - 1
                                                ? null
                                                : () => _move(entry.key, 1),
                                            icon: const Icon(
                                                Icons.arrow_downward)),
                                        TextButton(
                                            onPressed: _busy
                                                ? null
                                                : () => _run(() async {
                                                      await _service.remove(
                                                          _collection!,
                                                          entry.value.id);
                                                      _items
                                                          .removeAt(entry.key);
                                                      _collection = await _service
                                                          .saveOrder(
                                                              _collection!.id,
                                                              _items
                                                                  .map((i) =>
                                                                      i.id)
                                                                  .toList());
                                                    }),
                                            child: const Text(
                                                'Retirar da coleção')),
                                      ]),
                                  ])))),
                        ],
                      ])))));
}

class _ItemPicker extends StatefulWidget {
  const _ItemPicker({required this.service, required this.excluded});
  final CollectionService service;
  final Set<int> excluded;
  @override
  State<_ItemPicker> createState() => _ItemPickerState();
}

class _ItemPickerState extends State<_ItemPicker> {
  final _search = TextEditingController();
  List<LivingClueModel> _items = [];
  bool _busy = false, _more = true;
  int _offset = 0;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load(true);
  }

  Future<void> _load(bool reset) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      if (reset) {
        _offset = 0;
        _items = [];
      }
    });
    try {
      final page = await widget.service.clues
          .fetch(search: _search.text.trim(), offset: _offset, limit: 20);
      if (mounted)
        setState(() {
          _offset += page.length;
          _more = page.length == 20;
          _items.addAll(page.where((i) => !widget.excluded.contains(i.id)));
        });
    } catch (_) {
      if (mounted) setState(() => _error = 'Falha na busca. Tente novamente.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('Adicionar à coleção'),
          content: SizedBox(
              width: 500,
              height: 420,
              child: Column(children: [
                TextField(
                    controller: _search,
                    onSubmitted: (_) => _load(true),
                    decoration: InputDecoration(
                        labelText: 'Buscar no acervo',
                        suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _busy ? null : () => _load(true)))),
                if (_busy) const LinearProgressIndicator(),
                if (_error != null)
                  TextButton(
                      onPressed: () => _load(false), child: Text(_error!)),
                Expanded(
                    child: ListView(children: [
                  ..._items.map((i) => ListTile(
                      title: Text(i.name),
                      onTap: () => Navigator.pop(context, i))),
                  if (_more && !_busy)
                    TextButton(
                        onPressed: () => _load(false),
                        child: const Text('Carregar mais')),
                ])),
              ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'))
          ]);
}
