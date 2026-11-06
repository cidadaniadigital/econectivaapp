import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pvalidator/pvalidator.dart';
import 'package:unisinos_usp_app/controllers/node_link/node_link_create_controller.dart';
import 'package:unisinos_usp_app/models/node_link_model.dart';
import 'package:unisinos_usp_app/webclients/node_webclient.dart';
import 'package:unisinos_usp_app/widgets/action_button.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';
import 'package:widgets_spo/widgets_spo.dart';

class NodeLinkCreateScreen extends StatefulWidget {
  const NodeLinkCreateScreen({super.key});

  @override
  State<NodeLinkCreateScreen> createState() => _NodeLinkCreateScreenState();
}

class _NodeLinkCreateScreenState extends State<NodeLinkCreateScreen> {
  final NodeLinkCreateController _controller = Get.find<NodeLinkCreateController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final ItemSelectController _sourceNodeSelectController = ItemSelectController();
  final ItemSelectController _targetNodeSelectController = ItemSelectController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        leading: const SafeBackButton(),
        title: const Text('Nova ligação'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          SingleChildScrollView(
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
                        title: loading ? 'Salvando...' : 'Salvar',
                        onPressed: loading ? null : _save,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final int? sourceNodeId = _sourceNodeSelectController.selectedItem?.id;
    final int? targetNodeId = _targetNodeSelectController.selectedItem?.id;

    if (sourceNodeId == null || targetNodeId == null) {
      Get.customSnackbar('Erro', 'Selecione os dois nós para criar a ligação.');
      return;
    }
    if (sourceNodeId == targetNodeId) {
      Get.customSnackbar('Erro', 'Escolha nós diferentes para criar a ligação.');
      return;
    }

    final model = NodeLinkModel(
      id: 0,
      sourceNodeId: sourceNodeId,
      targetNodeId: targetNodeId,
    );

    final bool saved = await _controller.save(model);
    if (saved) {
      Get.secureBack(result: true);
    }
  }
}
