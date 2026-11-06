import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/models/category_model.dart';
import 'package:unisinos_usp_app/widgets/category_map_marker.dart';

class CategoryIconPicker extends StatelessWidget {
  const CategoryIconPicker({
    super.key,
    required this.controller,
    required this.name,
    required this.type,
    required this.color,
  });
  final TextEditingController controller;
  final String name;
  final String type;
  final Color color;
  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<TextEditingValue>(
    valueListenable: controller,
    builder: (context, value, _) {
      final code = value.text.trim();
      final category = CategoryModel(
        id: 0,
        name: name,
        type: type,
        colorHex: '',
        metadataTags: '',
        iconCode: code,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ícone no mapa',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CategoryMapMarker(color: color, icon: categoryMapIcon(category)),
              const SizedBox(width: 14),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey(code),
                  initialValue: code,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Símbolo da categoria',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Automático pela categoria'),
                    ),
                    if (code.isNotEmpty && !categoryMapIcons.containsKey(code))
                      DropdownMenuItem(
                        value: code,
                        child: const Text('Ícone anterior (compatibilidade)'),
                      ),
                    for (final entry in categoryMapIcons.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Row(
                          children: [
                            Icon(entry.value.$2, size: 20),
                            const SizedBox(width: 10),
                            Flexible(child: Text(entry.value.$1)),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (code) {
                    if (code != null) controller.text = code;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'O símbolo aparece dentro do marcador, com a cor da categoria.',
          ),
        ],
      );
    },
  );
}
