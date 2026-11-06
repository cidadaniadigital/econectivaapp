import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/territory/territory_index_controller.dart';
import 'package:unisinos_usp_app/models/territory_model.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';

class TerritoryIndexScreen extends StatelessWidget {
  TerritoryIndexScreen({super.key});
  final TerritoryIndexController _controller =
      Get.find<TerritoryIndexController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: const SafeBackButton(),
        title: const Text('Territórios'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _goToCreate),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Obx(
                  () => DropdownButtonFormField<int?>(
                    value: _controller.selectedBiomeId.value,
                    dropdownColor: Colors.grey.shade900,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por bioma',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Todos os biomas'),
                      ),
                      ..._controller.biomes.map(
                        (b) => DropdownMenuItem<int?>(
                          value: b.id,
                          child: Text(b.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      _controller.selectedBiomeId.value = value;
                      _controller.loadTerritories();
                    },
                  ),
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (_controller.isLoading.value &&
                      _controller.territories.isEmpty)
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  if (_controller.territories.isEmpty)
                    return const Center(
                      child: Text(
                        'Nenhum território cadastrado.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    itemCount: _controller.territories.length,
                    itemBuilder: (_, index) {
                      final TerritoryModel model =
                          _controller.territories[index];
                      return Card(
                        color: Colors.black.withValues(alpha: 0.58),
                        child: ListTile(
                          title: Text(
                            model.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '${model.type} • ${model.biome?.name ?? 'Bioma ${model.biomeId}'}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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

  void _confirmDelete(TerritoryModel model) {
    Get.defaultDialog(
      title: 'Excluir território',
      middleText: 'Deseja realmente excluir "${model.name}"?',
      textCancel: 'Cancelar',
      textConfirm: 'Excluir',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        _controller.deleteTerritory(model);
      },
    );
  }

  Future<void> _goToCreate() async {
    await Get.toNamed('/territories/create');
    await _controller.loadTerritories();
  }

  Future<void> _goToUpdate(TerritoryModel model) async {
    await Get.toNamed(
      '/territories/update',
      parameters: {'id': model.id.toString()},
    );
    await _controller.loadTerritories();
  }
}
