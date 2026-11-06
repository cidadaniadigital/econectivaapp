import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/connection_type/connection_type_index_controller.dart';
import 'package:unisinos_usp_app/models/connection_type_model.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';

class ConnectionTypeIndexScreen extends StatelessWidget {
  ConnectionTypeIndexScreen({super.key});

  final ConnectionTypeIndexController _controller =
      Get.find<ConnectionTypeIndexController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        leading: const SafeBackButton(),
        title: const Text('Tipos de conexão'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _goToCreate,
            tooltip: 'Novo tipo',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          Obx(() {
            if (_controller.isLoading.value &&
                _controller.connectionTypes.isEmpty) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }
            if (_controller.connectionTypes.isEmpty) {
              return const Center(
                  child: Text('Nenhum tipo cadastrado.',
                      style: TextStyle(color: Colors.white)));
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: _controller.connectionTypes.length,
                    itemBuilder: (_, index) {
                      final ConnectionTypeModel model =
                          _controller.connectionTypes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        color: Colors.black.withValues(alpha: 0.58),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      model.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                    ),
                                  ),
                                  Chip(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.15),
                                    label: Text(
                                      model.isDirectional
                                          ? 'Direcional'
                                          : 'Bidirecional',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Estilo: ${model.strokeStyle}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    color: Colors.white,
                                    icon: const Icon(Icons.edit),
                                    onPressed: _controller.isLoading.value
                                        ? null
                                        : () => _goToUpdate(model),
                                    tooltip: 'Editar',
                                  ),
                                  IconButton(
                                    color: Colors.white,
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: _controller.isLoading.value
                                        ? null
                                        : () => _confirmDelete(model),
                                    tooltip: 'Excluir',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_controller.isLoading.value)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _confirmDelete(ConnectionTypeModel model) {
    Get.defaultDialog(
      title: 'Excluir tipo',
      middleText: 'Deseja realmente excluir "${model.name}"?',
      textCancel: 'Cancelar',
      textConfirm: 'Excluir',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        _controller.deleteConnectionType(model);
      },
    );
  }

  Future<void> _goToCreate() async {
    await Get.toNamed('/connection_types/create');
    await _controller.loadConnectionTypes();
  }

  Future<void> _goToUpdate(ConnectionTypeModel model) async {
    await Get.toNamed('/connection_types/update',
        parameters: {'id': model.id.toString()});
    await _controller.loadConnectionTypes();
  }
}
