import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/clue_connection/clue_connection_index_controller.dart';
import 'package:unisinos_usp_app/models/clue_connection_model.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';

class ClueConnectionIndexScreen extends StatelessWidget {
  ClueConnectionIndexScreen({super.key});

  final ClueConnectionIndexController _controller =
      Get.find<ClueConnectionIndexController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        leading: const SafeBackButton(),
        title: const Text('Conexões'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _goToCreate,
            tooltip: 'Nova conexão',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          Obx(() {
            if (_controller.isLoading.value &&
                _controller.connections.isEmpty) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }
            if (_controller.connections.isEmpty) {
              return const Center(
                  child: Text('Nenhuma conexão cadastrada.',
                      style: TextStyle(color: Colors.white)));
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: _controller.connections.length,
                    itemBuilder: (_, index) {
                      final ClueConnectionModel model =
                          _controller.connections[index];
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
                              _connectionHeader(context, model),
                              const SizedBox(height: 6),
                              Text(
                                'Força ${model.strength}${model.evidence != null ? " • Evidência: ${model.evidence}" : ""}',
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

  Widget _connectionHeader(BuildContext context, ClueConnectionModel model) {
    final title = '${_controller.clueLabel(model.sourceClueId)} → '
        '${_controller.clueLabel(model.targetClueId)}';
    final relation = _controller.connectionTypeLabel(model.connectionTypeId);
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, bounds) {
      final label = Text(title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold));
      final badge = Chip(
        backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.15),
        label: Text(relation,
            style: TextStyle(color: theme.colorScheme.secondary)),
      );
      if (bounds.maxWidth < 480) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [label, const SizedBox(height: 8), badge]);
      }
      return Row(
          children: [Expanded(child: label), const SizedBox(width: 12), badge]);
    });
  }

  void _confirmDelete(ClueConnectionModel model) {
    Get.defaultDialog(
      title: 'Excluir conexão',
      middleText: 'Deseja realmente excluir a conexão?',
      textCancel: 'Cancelar',
      textConfirm: 'Excluir',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        _controller.deleteConnection(model);
      },
    );
  }

  Future<void> _goToCreate() async {
    await Get.toNamed('/clue_connections/create');
    await _controller.loadConnections();
  }

  Future<void> _goToUpdate(ClueConnectionModel model) async {
    await Get.toNamed('/clue_connections/update',
        parameters: {'id': model.id.toString()});
    await _controller.loadConnections();
  }
}
