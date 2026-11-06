import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pvalidator/pvalidator.dart';
import 'package:unisinos_usp_app/controllers/clue_connection/clue_connection_create_controller.dart';
import 'package:unisinos_usp_app/models/clue_connection_model.dart';
import 'package:unisinos_usp_app/webclients/connection_type_webclient.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';
import 'package:unisinos_usp_app/widgets/action_button.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';
import 'package:widgets_spo/widgets_spo.dart';

class ClueConnectionCreateScreen extends StatefulWidget {
  const ClueConnectionCreateScreen({super.key});

  @override
  State<ClueConnectionCreateScreen> createState() =>
      _ClueConnectionCreateScreenState();
}

class _ClueConnectionCreateScreenState
    extends State<ClueConnectionCreateScreen> {
  final ClueConnectionCreateController _controller =
      Get.find<ClueConnectionCreateController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final ItemSelectController _sourceSelectController = ItemSelectController();
  final ItemSelectController _targetSelectController = ItemSelectController();
  final ItemSelectController _typeSelectController = ItemSelectController();
  final TextEditingController _strengthController =
      TextEditingController(text: '1');
  final TextEditingController _evidenceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      final sourceId = args['sourceId'];
      final sourceName = args['sourceName'];
      final targetId = args['targetId'];
      final targetName = args['targetName'];

      if (sourceId is int && sourceName is String && sourceName.isNotEmpty) {
        _sourceSelectController.selectedItem = ItemSelect(
          id: sourceId,
          name: sourceName,
        );
      }
      if (targetId is int && targetName is String && targetName.isNotEmpty) {
        _targetSelectController.selectedItem = ItemSelect(
          id: targetId,
          name: targetName,
        );
      }
    }
  }

  @override
  void dispose() {
    _strengthController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        leading: const SafeBackButton(),
        title: const Text('Nova conexão'),
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
                    label: '',
                    hint: 'Pista origem',
                    controller: _sourceSelectController,
                    enable: _sourceSelectController.selectedItem == null,
                    validator: (value) => PValidator([
                      PRuleRequired(value, message: 'Obrigatório'),
                    ]).val(),
                    onFind: (search, offset, params) =>
                        LivingClueWebclient().select(search, offset),
                  ),
                  Insets.large.height,
                  InputSelectApi(
                    label: '',
                    hint: 'Pista destino',
                    controller: _targetSelectController,
                    enable: _targetSelectController.selectedItem == null,
                    validator: (value) => PValidator([
                      PRuleRequired(value, message: 'Obrigatório'),
                    ]).val(),
                    onFind: (search, offset, params) =>
                        LivingClueWebclient().select(search, offset),
                  ),
                  Insets.large.height,
                  InputSelectApi(
                    label: '',
                    hint: 'Tipo de conexão',
                    controller: _typeSelectController,
                    validator: (value) => PValidator([
                      PRuleRequired(value, message: 'Obrigatório'),
                    ]).val(),
                    onFind: (search, offset, params) =>
                        ConnectionTypeWebclient().select(search, offset),
                  ),
                  Insets.large.height,
                  InputNumber(
                    label: 'Força',
                    controller: _strengthController,
                    validator: (value) => PValidator([
                      PRuleInteger(value, message: 'Use um número inteiro'),
                    ]).val(),
                  ),
                  Insets.large.height,
                  InputText(
                    hintText: 'Evidência (opcional)',
                    controller: _evidenceController,
                    maxLines: 3,
                  ),
                  Insets.extraLarge.height,
                  SizedBox(
                    width: double.infinity,
                    child: Obx(() {
                      final bool loading = _controller.isLoading.value;
                      final String buttonTitle =
                          loading ? 'Salvando...' : 'Salvar';
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
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final int? sourceId = _sourceSelectController.selectedItem?.id;
    final int? targetId = _targetSelectController.selectedItem?.id;
    final int? typeId = _typeSelectController.selectedItem?.id;
    final int? strength = int.tryParse(_strengthController.text.trim().isEmpty
        ? '1'
        : _strengthController.text.trim());
    if (sourceId == null ||
        targetId == null ||
        typeId == null ||
        strength == null) {
      return;
    }
    if (sourceId == targetId) {
      Get.customSnackbar(
        'Atenção',
        'A pista destino deve ser diferente da origem.',
      );
      return;
    }

    final model = ClueConnectionModel(
      id: 0,
      sourceClueId: sourceId,
      targetClueId: targetId,
      connectionTypeId: typeId,
      strength: strength,
      evidence: _evidenceController.text.trim().isEmpty
          ? null
          : _evidenceController.text.trim(),
    );

    final bool saved = await _controller.save(model);
    if (saved) {
      Get.secureBack(result: true);
    }
  }
}
