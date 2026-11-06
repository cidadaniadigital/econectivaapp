import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/services/collection_service.dart';
import 'package:unisinos_usp_app/widgets/catalog_shelf.dart';
import 'package:unisinos_usp_app/widgets/category_map_marker.dart';
import 'package:unisinos_usp_app/widgets/clue_cover.dart';

/// Discovery uses real categories and image covers from the catalogue.
class DiscoveryContent extends StatelessWidget {
  const DiscoveryContent(
      {super.key,
      required this.items,
      required this.search,
      required this.onSearch,
      required this.onCatalog,
      required this.onMap,
      required this.onCategory,
      required this.onOpen,
      required this.personal});
  final List<LivingClueModel> items;
  final TextEditingController search;
  final VoidCallback onSearch, onCatalog, onMap;
  final void Function(int) onCategory;
  final void Function(LivingClueModel) onOpen;
  final Widget personal;

  // A fresh selection on app load, stable during search/layout rebuilds.
  static final int _heroSeed = Random().nextInt(1 << 30);

  /// Random covers without changing catalogue order or repeating a clue.
  static List<LivingClueModel> heroItems(List<LivingClueModel> items,
      {Random? random}) {
    final eligible = items
        .where((item) =>
            !CollectionService.isCollection(item) &&
            ClueCover.hasOwnImage(item))
        .toList()
      ..shuffle(random ?? Random(_heroSeed));
    return eligible.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 700;
    final featured = items
        .where((e) => e.metadata?['destaque_catalogo'] == true)
        .take(3)
        .toList();
    final collections = items.where(CollectionService.isCollection).toList();
    final clues =
        items.where((e) => !CollectionService.isCollection(e)).toList();
    final visual = heroItems(items);
    final recent = clues.where((e) => e.createdAt != null).toList()
      ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    final categories = <int, LivingClueModel>{};
    for (final item in clues) {
      if (item.category != null)
        categories.putIfAbsent(item.categoryId, () => item);
    }
    final intro =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('ATOPOS / CIDADANIA DIGITAL',
          style: theme.textTheme.labelLarge
              ?.copyWith(letterSpacing: 2, color: const Color(0xFF67DFCC))),
      const SizedBox(height: 18),
      Text('Descobertas que\ncriam conexões.',
          style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700, color: Colors.white, height: 1.12)),
      const SizedBox(height: 18),
      const Text(
          'Explore pessoas, territórios e conhecimentos. Cada pista abre um caminho para compreender e participar do mundo conectado.',
          style:
              TextStyle(color: Color(0xFFCFDCE8), fontSize: 17, height: 1.6)),
      const SizedBox(height: 24),
      Wrap(spacing: 12, runSpacing: 12, children: [
        FilledButton.icon(
            onPressed: onCatalog,
            icon: const Icon(Icons.explore_outlined),
            label: const Text('Explorar o acervo')),
        OutlinedButton.icon(
            onPressed: onMap,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Explorar o mapa')),
      ]),
    ]);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (compact) ...[_searchField(), const SizedBox(height: 20)],
      Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                  colors: [Color(0xFF133E47), Color(0xFF112337)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)),
          child: LayoutBuilder(builder: (context, size) {
            final collage = visual.isEmpty
                ? const SizedBox.shrink()
                : SizedBox(
                    height: 300,
                    child: Row(children: [
                      Expanded(
                          flex: 3,
                          child: _CoverLink(
                              clue: visual.first, onOpen: onOpen, height: 300)),
                      if (visual.length > 1) ...[
                        const SizedBox(width: 12),
                        Expanded(
                            flex: 2,
                            child: Column(children: [
                              Expanded(
                                  child: _CoverLink(
                                      clue: visual[1],
                                      onOpen: onOpen,
                                      height: 144)),
                              if (visual.length > 2) ...[
                                const SizedBox(height: 12),
                                Expanded(
                                    child: _CoverLink(
                                        clue: visual[2],
                                        onOpen: onOpen,
                                        height: 144))
                              ],
                            ]))
                      ],
                    ]));
            return size.maxWidth < 750 || visual.isEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        intro,
                        if (visual.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          collage
                        ]
                      ])
                : Row(children: [
                    Expanded(child: intro),
                    const SizedBox(width: 36),
                    Expanded(child: collage)
                  ]);
          })),
      const SizedBox(height: 28),
      if (!compact) _searchField(),
      if (items.isEmpty)
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Text('O acervo ainda não tem registros disponíveis.')),
      if (featured.isNotEmpty) ...[
        _title(context, 'Em destaque',
            'Uma seleção da curadoria para começar a explorar.'),
        ...featured.map((clue) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                    onTap: () => onOpen(clue),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClueCover(clue: clue, height: 240),
                          Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(clue.name,
                                        style: theme.textTheme.headlineSmall),
                                    const SizedBox(height: 8),
                                    Text(
                                        clue.metadata?[
                                                    'destaque_catalogo_texto']
                                                ?.toString() ??
                                            clue.description ??
                                            '',
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 8),
                                    const Text('Explorar →'),
                                  ]))
                        ]))))),
      ],
      if (categories.isNotEmpty) ...[
        _title(context, 'Explore por interesse',
            'Escolha uma categoria do acervo.'),
        LayoutBuilder(builder: (context, bounds) {
          final columns = bounds.maxWidth < 500
              ? 1
              : bounds.maxWidth < 850
                  ? 2
                  : 3;
          final width = (bounds.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: categories.values
                  .map((item) => SizedBox(
                      width: width,
                      child: Card(
                          child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Icon(categoryMapIcon(item.category),
                                  size: 30),
                              title: Text(item.category!.name),
                              trailing:
                                  const Icon(Icons.arrow_forward, size: 18),
                              onTap: () => onCategory(item.categoryId)))))
                  .toList());
        }),
      ],
      const SizedBox(height: 32),
      Card(
          color: const Color(0xFF173C43),
          child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.layers_outlined,
                        size: 42, color: Color(0xFF67DFCC)),
                    const SizedBox(height: 14),
                    Text('O acervo também tem território',
                        style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 10),
                    const Text(
                        'Encontre pistas no mapa e explore camadas de vegetação, relevo, água e outros dados ambientais.',
                        style: TextStyle(height: 1.5)),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                        onPressed: onMap,
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Abrir mapa e camadas')),
                  ]))),
      if (collections.isNotEmpty) ...[
        _title(context, 'Coleções temáticas',
            'Percursos que aproximam pistas e ideias.'),
        ...collections.map((clue) => _CollectionDiscoveryCard(
            key: ValueKey(clue.id), clue: clue, onOpen: onOpen)),
      ],
      if (recent.isNotEmpty)
        CatalogShelf(
            title: 'Novidades do acervo',
            itemCount: recent.take(12).length,
            itemBuilder: (context, index) {
              final clue = recent[index];
              return SizedBox(
                  width: 252,
                  child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                          onTap: () => onOpen(clue),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ClueCover(clue: clue, height: 142),
                                Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(clue.name,
                                              style:
                                                  theme.textTheme.titleMedium,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 8),
                                          Text(
                                              'Adicionada em ${DateFormat('dd/MM/yyyy').format(clue.createdAt!.toLocal())}',
                                              style: theme.textTheme.bodySmall),
                                        ])),
                              ]))));
            }),
      _title(
          context, 'Seu espaço', 'Retome referências e participe do acervo.'),
      personal,
      const SizedBox(height: 32),
    ]);
  }

  Widget _searchField() => TextField(
      controller: search,
      onSubmitted: (_) => onSearch(),
      decoration: InputDecoration(
          labelText: 'O que você deseja explorar?',
          hintText: 'Busque títulos e descrições do acervo',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          suffixIcon: IconButton(
              tooltip: 'Pesquisar acervo',
              onPressed: onSearch,
              icon: const Icon(Icons.arrow_forward))));

  Widget _title(BuildContext context, String title, String subtitle) => Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(subtitle),
      ]));
}

class _CoverLink extends StatelessWidget {
  const _CoverLink(
      {required this.clue, required this.onOpen, required this.height});
  final LivingClueModel clue;
  final void Function(LivingClueModel) onOpen;
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Material(
          child: InkWell(
              onTap: () => onOpen(clue),
              child: Semantics(
                  label: 'Explorar ${clue.name}',
                  button: true,
                  child: Stack(fit: StackFit.expand, children: [
                    ClueCover(clue: clue, height: height),
                    const DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                          Colors.transparent,
                          Color(0xDD071A23)
                        ]))),
                    Positioned(
                        left: 14,
                        right: 14,
                        bottom: 14,
                        child: Text(clue.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))),
                  ])))));
}

class _CollectionDiscoveryCard extends StatefulWidget {
  const _CollectionDiscoveryCard(
      {super.key, required this.clue, required this.onOpen});
  final LivingClueModel clue;
  final void Function(LivingClueModel) onOpen;
  @override
  State<_CollectionDiscoveryCard> createState() =>
      _CollectionDiscoveryCardState();
}

class _CollectionDiscoveryCardState extends State<_CollectionDiscoveryCard> {
  late final Future<List<LivingClueModel>> members =
      CollectionService().items(widget.clue);
  @override
  Widget build(BuildContext context) => FutureBuilder<List<LivingClueModel>>(
      future: members,
      builder: (context, data) => Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: () => widget.onOpen(widget.clue),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClueCover(
                        clue: widget.clue,
                        collectionItems: data.data ?? const [],
                        height: 180),
                    Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.clue.name,
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              if ((widget.clue.description ?? '').isNotEmpty)
                                Text(widget.clue.description!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 10),
                              Text(data.hasData
                                  ? '${data.data!.length} itens'
                                  : data.hasError
                                      ? 'Abra a coleção para consultar os itens'
                                      : 'Consultando itens…'),
                            ])),
                  ]))));
}
