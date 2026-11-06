import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/node_type/node_type_index_controller.dart';
import 'package:unisinos_usp_app/models/node_type_model.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';

class NodeTypeIndexScreen extends StatefulWidget {
  NodeTypeIndexScreen({super.key});

  @override
  State<NodeTypeIndexScreen> createState() => _NodeTypeIndexScreenState();
}

class _NodeTypeIndexScreenState extends State<NodeTypeIndexScreen> {
  final NodeTypeIndexController _controller = Get.find<NodeTypeIndexController>();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        leading: const SafeBackButton(),
        title: const Text('Tipos de nó'),
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
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      onPressed: () => _controller.applySearch(_searchController.text),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: _controller.applySearch,
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (_controller.isLoading.value && _controller.nodeTypes.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }
                  if (_controller.nodeTypes.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhum tipo de nó encontrado.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: _controller.nodeTypes.length + (_controller.isLoadingMore.value ? 1 : 0),
                    itemBuilder: (_, index) {
                      if (index >= _controller.nodeTypes.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final model = _controller.nodeTypes[index];
                      return _NodeTypeCard(
                        model: model,
                        onEdit: () => _goToUpdate(model),
                        onDelete: () => _confirmDelete(model),
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

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _controller.loadMore();
    }
  }

  void _confirmDelete(NodeTypeModel model) {
    Get.defaultDialog(
      title: 'Excluir tipo',
      middleText: 'Deseja realmente excluir "${model.name}"?',
      textCancel: 'Cancelar',
      textConfirm: 'Excluir',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        _controller.deleteNodeType(model);
      },
    );
  }

  Future<void> _goToCreate() async {
    final created = await Get.toNamed('/node_types/create');
    if (created == true) {
      await _controller.loadInitial();
    }
  }

  Future<void> _goToUpdate(NodeTypeModel model) async {
    final updated = await Get.toNamed('/node_types/update', parameters: {'id': model.id.toString()});
    if (updated == true) {
      await _controller.loadInitial();
    }
  }
}

class _NodeTypeCard extends StatelessWidget {
  const _NodeTypeCard({
    required this.model,
    required this.onEdit,
    required this.onDelete,
  });

  final NodeTypeModel model;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final Color color = _parseHexColor(model.color);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.black.withValues(alpha: 0.58),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    model.color,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, color: Colors.white),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseHexColor(String value) {
    final String hex = value.replaceAll('#', '').padLeft(6, '0');
    return Color(int.parse('FF$hex', radix: 16));
  }
}
