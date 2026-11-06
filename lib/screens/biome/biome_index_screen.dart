import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/biome/biome_index_controller.dart';
import 'package:unisinos_usp_app/models/biome_model.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';

class BiomeIndexScreen extends StatelessWidget {
  BiomeIndexScreen({super.key});
  final BiomeIndexController _controller = Get.find<BiomeIndexController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: const SafeBackButton(),
        title: const Text('Biomas'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _goToCreate),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          Obx(() {
            if (_controller.isLoading.value && _controller.biomes.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            if (_controller.biomes.isEmpty) {
              return const Center(
                child: Text(
                  'Nenhum bioma cadastrado.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _controller.biomes.length,
              itemBuilder: (_, index) {
                final BiomeModel model = _controller.biomes[index];
                return Card(
                  color: Colors.black.withValues(alpha: 0.58),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _parseColor(model.colorHex),
                    ),
                    title: Text(
                      model.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      model.slug,
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
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (_) {
      return Colors.grey;
    }
  }

  void _confirmDelete(BiomeModel model) {
    Get.defaultDialog(
      title: 'Excluir bioma',
      middleText: 'Deseja realmente excluir "${model.name}"?',
      textCancel: 'Cancelar',
      textConfirm: 'Excluir',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        _controller.deleteBiome(model);
      },
    );
  }

  Future<void> _goToCreate() async {
    await Get.toNamed('/biomes/create');
    await _controller.loadBiomes();
  }

  Future<void> _goToUpdate(BiomeModel model) async {
    await Get.toNamed(
      '/biomes/update',
      parameters: {'id': model.id.toString()},
    );
    await _controller.loadBiomes();
  }
}
