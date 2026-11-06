import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/category/category_index_controller.dart';
import 'package:unisinos_usp_app/models/category_model.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';

class CategoryIndexScreen extends StatelessWidget {
  CategoryIndexScreen({super.key});

  final CategoryIndexController _controller =
      Get.find<CategoryIndexController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        leading: const SafeBackButton(),
        title: const Text('Categorias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _goToCreate,
            tooltip: 'Nova categoria',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: StarfieldBackground(),
          ),
          Obx(() {
            if (_controller.isLoading.value && _controller.categories.isEmpty) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }

            if (_controller.categories.isEmpty) {
              return const Center(
                child: Text(
                  'Nenhuma categoria cadastrada.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
                    itemCount: _controller.categories.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Colors.white24),
                    itemBuilder: (_, index) {
                      final CategoryModel category =
                          _controller.categories[index];
                      return ListTile(
                        leading: _ColorDot(colorHex: category.colorHex),
                        title: Text(category.name,
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              category.type,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            if ((category.description ?? '').isNotEmpty)
                              Text(
                                category.description ?? '',
                                style: const TextStyle(color: Colors.white54),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              color: Colors.white,
                              icon: const Icon(Icons.edit),
                              onPressed: _controller.isLoading.value
                                  ? null
                                  : () => _goToUpdate(category),
                              tooltip: 'Editar',
                            ),
                            IconButton(
                              color: Colors.white,
                              icon: const Icon(Icons.delete_outline),
                              onPressed: _controller.isLoading.value
                                  ? null
                                  : () => _confirmDelete(category),
                              tooltip: 'Excluir',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (_controller.isLoading.value)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _confirmDelete(CategoryModel category) {
    Get.defaultDialog(
      title: 'Excluir categoria',
      middleText: 'Deseja realmente excluir "${category.name}"?',
      textCancel: 'Cancelar',
      textConfirm: 'Excluir',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        _controller.deleteCategory(category);
      },
    );
  }

  Future<void> _goToCreate() async {
    await Get.toNamed('/categories/create');
    await _controller.loadCategories();
  }

  Future<void> _goToUpdate(CategoryModel category) async {
    await Get.toNamed('/categories/update',
        parameters: {'id': category.id.toString()});
    await _controller.loadCategories();
  }
}

class _ColorDot extends StatelessWidget {
  final String colorHex;

  const _ColorDot({required this.colorHex});

  @override
  Widget build(BuildContext context) {
    Color color;
    try {
      color = Color(int.parse(colorHex.replaceFirst('#', '0xff')));
    } catch (_) {
      color = Colors.grey;
    }
    return CircleAvatar(
      backgroundColor: color,
      radius: 16,
      child: const SizedBox.shrink(),
    );
  }
}
