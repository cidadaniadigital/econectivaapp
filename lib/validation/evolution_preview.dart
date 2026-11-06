// Explicit local preview target; not imported by the production entrypoint.
import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/models/category_model.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/widgets/discovery_content.dart';

void main() => runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: _Preview()));

class _Preview extends StatefulWidget {
  const _Preview();
  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  final search = TextEditingController();
  String destination = '';
  final items = [
    for (final (id, name, image, categoryName) in [
      (1, 'Conhecimentos e territórios', '44-09a2d740c6d4.jpg', 'Pesquisas'),
      (2, 'Conexões da cidadania', '45-4cfca7c53cfd.jpg', 'Conteúdos'),
      (3, 'Olhares sobre o lugar', '46-9e1f5ea7588d.jpg', 'Lugares')
    ])
      LivingClueModel(
          id: id,
          name: name,
          categoryId: id,
          createdAt: DateTime(2026, 10, 29 - id),
          imageUrl: 'http://127.0.0.1:8827/covers/$image',
          category: CategoryModel(
              id: id,
              name: categoryName,
              type: CategoryType.online,
              colorHex: '#43D4C2',
              metadataTags: '')),
  ];
  void open(String value) => setState(() => destination = value);
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
      data: ThemeData.dark(useMaterial3: true)
          .copyWith(scaffoldBackgroundColor: const Color(0xFF0C1B29)),
      child: Scaffold(
          appBar:
              AppBar(title: const Text('ATOPOS • Prévia com dados sintéticos')),
          body: ListView(padding: const EdgeInsets.all(20), children: [
            Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: DiscoveryContent(
                        items: items,
                        search: search,
                        onSearch: () => open('Busca: ${search.text}'),
                        onCatalog: () => open('Catálogo'),
                        onMap: () => open('Mapa'),
                        onCategory: (id) => open('Categoria $id'),
                        onOpen: (clue) => open(clue.name),
                        personal: const Text(
                            'Itens salvos • Contribuições • Criar pista')))),
            Text(destination)
          ])));
}
