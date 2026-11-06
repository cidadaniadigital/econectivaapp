import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/living_clue/living_clue_index_controller.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';

class LivingClueIndexScreen extends StatelessWidget {
  LivingClueIndexScreen({super.key});
  final LivingClueIndexController _controller =
      Get.find<LivingClueIndexController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        leading: const SafeBackButton(),
        title: const Text('Pistas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Get.toNamed('/living_clues/map'),
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: _goToCreate),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Obx(
                  () => Column(
                    children: [
                      DropdownButtonFormField<int?>(
                        value: _controller.selectedCategoryId.value,
                        dropdownColor: Colors.grey.shade900,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Todas as categorias'),
                          ),
                          ..._controller.categories.map(
                            (c) => DropdownMenuItem<int?>(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          _controller.selectedCategoryId.value = value;
                          _controller.loadLivingClues();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (_controller.isLoading.value &&
                      _controller.livingClues.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  if (_controller.livingClues.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhuma pista cadastrada.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: _controller.livingClues.length,
                    itemBuilder: (_, index) {
                      final LivingClueModel model =
                          _controller.livingClues[index];
                      final subtitle = model.category?.name ??
                          'Categoria ${model.categoryId}';
                      return Card(
                        color: Colors.black.withValues(alpha: 0.58),
                        child: ListTile(
                          title: Text(
                            model.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            subtitle,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                color: Colors.white,
                                icon: const Icon(Icons.visibility_outlined),
                                onPressed: () => Get.toNamed(
                                  '/living_clues/show',
                                  arguments: model,
                                  parameters: {'id': model.id.toString()},
                                ),
                              ),
                              IconButton(
                                color: Colors.white,
                                icon: const Icon(Icons.edit),
                                onPressed: () => _goToUpdate(model),
                              ),
                              IconButton(
                                color: Colors.white,
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _confirmDelete(model),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(LivingClueModel model) {
    Get.defaultDialog(
      title: 'Excluir pista viva',
      middleText: 'Deseja realmente excluir "${model.name}"?',
      textCancel: 'Cancelar',
      textConfirm: 'Excluir',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        _controller.deleteLivingClue(model);
      },
    );
  }

  Future<void> _goToCreate() async {
    final result = await Get.toNamed('/living_clues/type_select');
    if (result == true) await _controller.loadLivingClues();
  }

  Future<void> _goToUpdate(LivingClueModel model) async {
    await Get.toNamed(
      '/living_clues/update',
      parameters: {'id': model.id.toString()},
    );
    await _controller.loadLivingClues();
  }
}
