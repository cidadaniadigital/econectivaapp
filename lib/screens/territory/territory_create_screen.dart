import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/territory/territory_create_controller.dart';
import 'package:unisinos_usp_app/models/territory_model.dart';
import 'package:pvalidator/pvalidator.dart';
import 'package:unisinos_usp_app/models/biome_model.dart';
import 'package:unisinos_usp_app/webclients/biome_webclient.dart';
import 'package:unisinos_usp_app/widgets/action_button.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';
import 'package:widgets_spo/widgets_spo.dart';

class _TerritoryForm extends StatefulWidget {
  const _TerritoryForm({
    required this.title,
    required this.onSave,
  });
  final String title;
  final TerritoryModel? initialModel = null;
  final Future<bool> Function(TerritoryModel model) onSave;

  @override
  State<_TerritoryForm> createState() => _TerritoryFormState();
}

class _TerritoryFormState extends State<_TerritoryForm> {
  final _formKey = GlobalKey<FormState>();
  final _biomeWebclient = BiomeWebclient();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _centerLatController = TextEditingController();
  final _centerLngController = TextEditingController();
  bool _isActive = true;
  bool _saving = false;
  List<BiomeModel> _biomes = [];
  int? _biomeId;

  @override
  void initState() {
    super.initState();
    final model = widget.initialModel;
    _nameController.text = model?.name ?? '';
    _typeController.text = model?.type ?? '';
    _descriptionController.text = model?.description ?? '';
    _centerLatController.text = model?.centerLat?.toString() ?? '';
    _centerLngController.text = model?.centerLng?.toString() ?? '';
    _isActive = model?.isActive ?? true;
    _biomeId = model?.biomeId;
    _loadBiomes();
  }

  Future<void> _loadBiomes() async {
    final list = await _biomeWebclient.fetch();
    if (mounted) setState(() => _biomes = list);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _descriptionController.dispose();
    _centerLatController.dispose();
    _centerLngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: const SafeBackButton(),
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  InputText(
                    hintText: 'Nome',
                    controller: _nameController,
                    validator: (v) => PValidator([
                      PRuleRequired(v, message: 'Obrigatório'),
                    ]).val(),
                  ),
                  Insets.large.height,
                  DropdownButtonFormField<int>(
                    value: _biomeId,
                    decoration: const InputDecoration(
                      labelText: 'Bioma',
                      border: OutlineInputBorder(),
                    ),
                    items: _biomes
                        .map(
                          (b) => DropdownMenuItem<int>(
                            value: b.id,
                            child: Text(b.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _biomeId = v),
                    validator: (v) => v == null ? 'Obrigatório' : null,
                  ),
                  Insets.large.height,
                  InputText(
                    hintText: 'Tipo',
                    controller: _typeController,
                    validator: (v) => PValidator([
                      PRuleRequired(v, message: 'Obrigatório'),
                    ]).val(),
                  ),
                  Insets.large.height,
                  InputText(
                    hintText: 'Descrição (opcional)',
                    controller: _descriptionController,
                    maxLines: 4,
                  ),
                  Insets.large.height,
                  InputNumber(
                    label: 'Latitude central (opcional)',
                    controller: _centerLatController,
                  ),
                  Insets.large.height,
                  InputNumber(
                    label: 'Longitude central (opcional)',
                    controller: _centerLngController,
                  ),
                  Insets.medium.height,
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ativo'),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  Insets.extraLarge.height,
                  SizedBox(
                    width: double.infinity,
                    child: ActionButton(
                      theme: ActionButtonTheme.blue,
                      title: _saving ? 'Salvando...' : 'Salvar',
                      onPressed: _saving ? null : _save,
                    ),
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
    if (!(_formKey.currentState?.validate() ?? false) || _biomeId == null)
      return;
    setState(() => _saving = true);
    final saved = await widget.onSave(
      TerritoryModel(
        id: widget.initialModel?.id ?? 0,
        name: _nameController.text.trim(),
        type: _typeController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        biomeId: _biomeId!,
        centerLat: _centerLatController.text.trim().isEmpty
            ? null
            : double.tryParse(_centerLatController.text.trim()),
        centerLng: _centerLngController.text.trim().isEmpty
            ? null
            : double.tryParse(_centerLngController.text.trim()),
        metadata: widget.initialModel?.metadata,
        isActive: _isActive,
      ),
    );
    if (mounted) setState(() => _saving = false);
    if (saved) Get.back(result: true);
  }
}

class TerritoryCreateScreen extends StatelessWidget {
  const TerritoryCreateScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TerritoryCreateController>();
    return _TerritoryForm(
      title: 'Novo território',
      onSave: (TerritoryModel model) => controller.save(model),
    );
  }
}
