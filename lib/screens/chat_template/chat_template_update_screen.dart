import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/chat_template/chat_template_update_controller.dart';
import 'package:unisinos_usp_app/models/chat_template_model.dart';
import 'package:unisinos_usp_app/screens/chat_template/chat_template_form.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';

class ChatTemplateUpdateScreen extends StatelessWidget {
  const ChatTemplateUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatTemplateUpdateController controller =
        Get.find<ChatTemplateUpdateController>();
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        leading: const SafeBackButton(),
        title: const Text('Editar agente'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          Obx(() {
            if (controller.templateId == null) {
              return const Center(
                  child: Text('Agente não informado.',
                      style: TextStyle(color: Colors.white)));
            }

            if (controller.isLoading.value &&
                controller.template.value == null) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }

            if (controller.template.value == null) {
              return const Center(
                  child: Text('Template não encontrado.',
                      style: TextStyle(color: Colors.white)));
            }

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  child: Column(
                    children: [
                      ChatTemplateForm(
                        key: ValueKey<int>(controller.template.value!.id),
                        initialValue: controller.template.value,
                        submitLabel: 'Atualizar',
                        isLoading: controller.isLoading.value,
                        showSources: false,
                        onSubmit: (value) async {
                          final ChatTemplateModel current =
                              controller.template.value!;
                          final bool saved = await controller.save(
                            ChatTemplateModel(
                              id: current.id,
                              name: value.name,
                              description: value.description,
                              systemInstruction: value.systemInstruction,
                              files: current.files,
                            ),
                          );
                          if (saved && context.mounted) {
                            Navigator.of(context).pop(true);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSourcesSection(context, controller),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: controller.isLoading.value
                              ? null
                              : () =>
                                  _confirmDeleteMessages(context, controller),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade300,
                            side: BorderSide(color: Colors.red.shade400),
                          ),
                          icon: const Icon(Icons.delete_sweep_outlined),
                          label: const Text(
                              'Excluir todas as mensagens do template'),
                        ),
                      ),
                    ],
                  ),
                ),
                if (controller.isLoading.value)
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: LinearProgressIndicator(),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSourcesSection(
    BuildContext context,
    ChatTemplateUpdateController controller,
  ) {
    final ChatTemplateModel? template = controller.template.value;
    final List<ChatTemplateFileModel> files = template?.files ?? const [];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Fontes de contexto',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                FilledButton.icon(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => _goToCreateSource(context, controller),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (files.isEmpty)
              const Text('Nenhuma fonte cadastrada.')
            else
              ...files.map(
                (file) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    title: Text(file.name.isNotEmpty ? file.name : 'Fonte'),
                    subtitle: Text(_sourceSubtitle(file)),
                    trailing: IconButton(
                      onPressed: controller.isLoading.value || file.id == null
                          ? null
                          : () => controller.deleteSource(file.id!),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Excluir fonte',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _sourceSubtitle(ChatTemplateFileModel file) {
    if ((file.sourceUrl ?? file.url ?? '').trim().isNotEmpty) {
      return file.sourceUrl ?? file.url ?? '';
    }
    if ((file.originalContent ?? file.content ?? '').trim().isNotEmpty) {
      return file.originalContent ?? file.content ?? '';
    }
    return file.resolvedType;
  }

  Future<void> _goToCreateSource(
    BuildContext context,
    ChatTemplateUpdateController controller,
  ) async {
    final int? id = controller.template.value?.id ?? controller.templateId;
    if (id == null) return;

    final dynamic result = await Get.toNamed(
      '/chat_templates/sources/create',
      parameters: {'id': id.toString()},
    );
    if (result == true) {
      await controller.loadTemplate(id);
    }
  }

  Future<void> _confirmDeleteMessages(
    BuildContext context,
    ChatTemplateUpdateController controller,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text(
          'Tem certeza que deseja excluir todas as mensagens deste template? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir tudo'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await controller.deleteAllMessages();
  }
}
