import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/chat_template/chat_template_index_controller.dart';
import 'package:unisinos_usp_app/models/chat_template_model.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';

class ChatTemplateIndexScreen extends StatefulWidget {
  ChatTemplateIndexScreen({super.key});

  @override
  State<ChatTemplateIndexScreen> createState() => _ChatTemplateIndexScreenState();
}

class _ChatTemplateIndexScreenState extends State<ChatTemplateIndexScreen> {
  final ChatTemplateIndexController _controller = Get.find<ChatTemplateIndexController>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        leading: const SafeBackButton(),
        title: const Text('Agentes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _goToCreate,
            tooltip: 'Novo agente',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          Obx(() {
            if (_controller.isLoading.value && _controller.templates.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            if (_controller.templates.isEmpty) {
              return RefreshIndicator(
                onRefresh: _controller.loadInitial,
                child: ListView(
                  children: const [
                    SizedBox(height: 220),
                    Center(child: Text('Nenhum template cadastrado.', style: TextStyle(color: Colors.white))),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _controller.loadInitial,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: _controller.templates.length + (_controller.isLoadingMore.value ? 1 : 0),
                itemBuilder: (_, index) {
                  if (index >= _controller.templates.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator(color: Colors.white)),
                    );
                  }

                  final ChatTemplateModel template = _controller.templates[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Colors.black.withValues(alpha: 0.58),
                    child: ListTile(
                      title: Text(template.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        template.description?.isNotEmpty == true
                            ? template.description!
                            : (template.systemInstruction?.isNotEmpty == true ? template.systemInstruction! : 'Sem descrição'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      onTap: () => _goToChat(template),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            color: Colors.white,
                            icon: const Icon(Icons.edit),
                            onPressed: () => _goToUpdate(template),
                            tooltip: 'Editar template',
                          ),
                          IconButton(
                            color: Colors.red.shade300,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmDelete(template),
                            tooltip: 'Excluir template',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _goToCreate() async {
    final dynamic result = await Get.toNamed('/chat_templates/create');
    if (result == true) {
      await _controller.loadInitial();
    }
  }

  Future<void> _goToUpdate(ChatTemplateModel template) async {
    final dynamic result = await Get.toNamed(
      '/chat_templates/update',
      parameters: {'id': template.id.toString()},
      arguments: template,
    );
    if (result == true) {
      await _controller.loadInitial();
    }
  }

  void _goToChat(ChatTemplateModel template) {
    Get.toNamed(
      '/chat_templates/chat',
      parameters: {'id': template.id.toString()},
      arguments: template,
    );
  }

  Future<void> _confirmDelete(ChatTemplateModel template) async {
    final bool? confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Excluir template'),
        content: Text('Deseja excluir o template "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _controller.deleteTemplate(template);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _controller.loadMore();
    }
  }
}
