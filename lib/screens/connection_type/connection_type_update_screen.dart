import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pvalidator/pvalidator.dart';
import 'package:unisinos_usp_app/controllers/connection_type/connection_type_update_controller.dart';
import 'package:unisinos_usp_app/models/connection_type_model.dart';
import 'package:unisinos_usp_app/widgets/action_button.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';
import 'package:widgets_spo/widgets_spo.dart';

class ConnectionTypeUpdateScreen extends StatefulWidget {
  const ConnectionTypeUpdateScreen({super.key});

  @override
  State<ConnectionTypeUpdateScreen> createState() => _ConnectionTypeUpdateScreenState();
}

class _ConnectionTypeUpdateScreenState extends State<ConnectionTypeUpdateScreen> {
  final ConnectionTypeUpdateController _controller = Get.find<ConnectionTypeUpdateController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _strokeStyleController = TextEditingController();
  bool _isDirectional = true;
  bool _filled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _strokeStyleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        leading: const SafeBackButton(),
        title: const Text('Editar tipo de conexão'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          Obx(() {
            if (_controller.connectionTypeId == null) {
              return const Center(child: Text('Tipo não informado.', style: TextStyle(color: Colors.white)));
            }
            if (_controller.isLoading.value && _controller.connectionType.value == null) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (_controller.connectionType.value == null) {
              return const Center(child: Text('Tipo não encontrado.', style: TextStyle(color: Colors.white)));
            }

            if (!_filled && _controller.connectionType.value != null) {
              final ConnectionTypeModel model = _controller.connectionType.value!;
              _nameController.text = model.name;
              _strokeStyleController.text = model.strokeStyle;
              _isDirectional = model.isDirectional;
              _filled = true;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                InputText(
                  hintText: 'Nome',
                  controller: _nameController,
                  validator: (value) => PValidator([
                    PRuleRequired(value, message: 'Obrigatório'),
                    PRuleMaxString(value, 100, message: 'Máximo de 100 caracteres'),
                  ]).val(),
                ),
                Insets.large.height,
                InputText(
                  hintText: 'Estilo de linha (solid/dashed/dotted)',
                  controller: _strokeStyleController,
                ),
                Insets.large.height,
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Direcional'),
                  value: _isDirectional,
                  onChanged: (val) => setState(() => _isDirectional = val),
                ),
                Insets.extraLarge.height,
                SizedBox(
                  width: double.infinity,
                  child: Obx(() {
                    final bool loading = _controller.isLoading.value;
                    final String buttonTitle = loading ? 'Atualizando...' : 'Atualizar';
                    return ActionButton(
                      theme: ActionButtonTheme.blue,
                      title: buttonTitle,
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

    final model = ConnectionTypeModel(
      id: _controller.connectionType.value?.id ?? _controller.connectionTypeId ?? 0,
      name: _nameController.text.trim(),
      strokeStyle: _strokeStyleController.text.trim().isEmpty ? 'solid' : _strokeStyleController.text.trim(),
      isDirectional: _isDirectional,
    );

    final bool saved = await _controller.save(model);
    if (saved) {
      Get.secureBack(result: true);
    }
  }
}
