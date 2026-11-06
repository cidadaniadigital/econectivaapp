import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/sample/sample_index_controller.dart';
import 'package:unisinos_usp_app/models/sample_model.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';

class SampleIndexScreen extends StatelessWidget {
  SampleIndexScreen({super.key});

  final SampleIndexController _controller = Get.find<SampleIndexController>();

  Future<void> _goToCreate() async {
    final result = await Get.toNamed('/samples/create');
    if (result == true) {
      await _controller.loadSamples();
    }
  }

  Future<void> _goToUpdate(SampleModel sample) async {
    final result = await Get.toNamed(
      '/samples/update',
      parameters: {'id': sample.id.toString()},
    );
    if (result == true) {
      await _controller.loadSamples();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(),
        title: const Text('Samples'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _goToCreate,
            tooltip: 'Novo',
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.samples.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_controller.samples.isEmpty) {
          return const Center(child: Text('Nenhum sample cadastrado.'));
        }

        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
                itemCount: _controller.samples.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final SampleModel sample = _controller.samples[index];
                  return ListTile(
                    title: Text(sample.name),
                    subtitle: Text(
                      'Unique: ${sample.sampleUnique}  Ordem: ${sample.orderNumber}  Detalhe: ${sample.sampleDetailId}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: _controller.isLoading.value
                              ? null
                              : () => _goToUpdate(sample),
                          tooltip: 'Editar',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: _controller.isLoading.value
                              ? null
                              : () => _confirmDelete(sample),
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
                child: CircularProgressIndicator(),
              ),
          ],
        );
      }),
    );
  }

  void _confirmDelete(SampleModel sample) {
    Get.defaultDialog(
      title: 'Excluir sample',
      middleText: 'Deseja realmente excluir "${sample.name}"?',
      textCancel: 'Cancelar',
      textConfirm: 'Excluir',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        _controller.deleteSample(sample);
      },
    );
  }
}
