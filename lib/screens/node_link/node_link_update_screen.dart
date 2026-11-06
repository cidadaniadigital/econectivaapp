import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pvalidator/pvalidator.dart';
import 'package:unisinos_usp_app/controllers/node_link/node_link_update_controller.dart';
import 'package:unisinos_usp_app/models/node_link_model.dart';
import 'package:unisinos_usp_app/webclients/node_webclient.dart';
import 'package:unisinos_usp_app/widgets/action_button.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';
import 'package:widgets_spo/widgets_spo.dart';

class NodeLinkUpdateScreen extends StatefulWidget {
  const NodeLinkUpdateScreen({super.key});

  @override
  State<NodeLinkUpdateScreen> createState() => _NodeLinkUpdateScreenState();
}

class _NodeLinkUpdateScreenState extends State<NodeLinkUpdateScreen> {
  final NodeLinkUpdateController _controller = Get.find<NodeLinkUpdateController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final ItemSelectController _sourceNodeSelectController = ItemSelectController();
  final ItemSelectController _targetNodeSelectController = ItemSelectController();
  bool _filled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        leading: const SafeBackButton(),
        title: const Text('Editar ligação'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          Obx(() {
            if (_controller.nodeLinkId == null) {
              return const Center(child: Text('Ligação não informada.', style: TextStyle(color: Colors.white)));
            }
            if (_controller.isLoading.value && _controller.nodeLink.value == null) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (_controller.nodeLink.value == null) {
              return const Center(child: Text('Ligação não encontrada.', style: TextStyle(color: Colors.white)));
            }

            if (!_filled) {
              final NodeLinkModel model = _controller.nodeLink.value!;
              _sourceNodeSelectController.selectedItem = ItemSelect(
                id: model.sourceNodeId,
                name: model.sourceNode?.name ?? 'Nó #${model.sourceNodeId}',
              );
              _targetNodeSelectController.selectedItem = ItemSelect(
                id: model.targetNodeId,
                name: model.targetNode?.name ?? 'Nó #${model.targetNodeId}',
              );
              _filled = true;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InputSelectApi(
                      label: 'Nó de origem',
                      controller: _sourceNodeSelectController,
                      validator: (value) => PValidator([
                        PRuleRequired(value, message: 'Obrigatório'),
                      ]).val(),
                      onFind: (search, offset, params) => NodeWebclient().select(search, offset),
                    ),
                    Insets.large.height,
                    InputSelectApi(
                      label: 'Nó de destino',
                      controller: _targetNodeSelectController,
                      validator: (value) => PValidator([
                        PRuleRequired(value, message: 'Obrigatório'),
                      ]).val(),
                      onFind: (search, offset, params) => NodeWebclient().select(search, offset),
                    ),
                    Insets.extraLarge.height,
                    SizedBox(
                      width: double.infinity,
                      child: Obx(() {
                        final loading = _controller.isLoading.value;
                        return ActionButton(
                          theme: ActionButtonTheme.blue,
                          title: loading ? 'Atualizando...' : 'Atualizar',
                          onPressed: loading ? null : _save,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final int? sourceNodeId = _sourceNodeSelectController.selectedItem?.id;
    final int? targetNodeId = _targetNodeSelectController.selectedItem?.id;

    if (sourceNodeId == null || targetNodeId == null) {
      Get.customSnackbar('Erro', 'Selecione os dois nós para atualizar a ligação.');
      return;
    }
    if (sourceNodeId == targetNodeId) {
      Get.customSnackbar('Erro', 'Escolha nós diferentes para manter a ligação válida.');
      return;
    }

    final model = NodeLinkModel(
      id: _controller.nodeLink.value?.id ?? _controller.nodeLinkId ?? 0,
      sourceNodeId: sourceNodeId,
      targetNodeId: targetNodeId,
    );

    final bool saved = await _controller.save(model);
    if (saved) {
      Get.secureBack(result: true);
    }
  }
}
