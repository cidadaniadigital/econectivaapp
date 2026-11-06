import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';
import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/widgets/rich_clue_editor.dart';
import 'package:unisinos_usp_app/widgets/clue_cover_editor.dart';
import 'package:get/get.dart';
import 'package:pvalidator/pvalidator.dart';
import 'package:unisinos_usp_app/controllers/living_clue/living_clue_create_controller.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/widgets/action_button.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';
import 'package:widgets_spo/widgets_spo.dart';

class LivingClueCreateScreen extends StatefulWidget {
  const LivingClueCreateScreen({super.key});

  @override
  State<LivingClueCreateScreen> createState() => _LivingClueCreateScreenState();
}

class _LivingClueCreateScreenState extends State<LivingClueCreateScreen> {
  final LivingClueCreateController _controller =
      Get.find<LivingClueCreateController>();
  final _coverSelection = CoverSelection();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _categoryController = TextEditingController();
  final Map<String, TextEditingController> _metadataControllers = {};
  List<String> _metadataTags = [];
  int? _categoryId;
  bool _isActive = true;
  String? _descriptionDelta;

  @override
  void initState() {
    super.initState();
    final args =
        Get.arguments is Map ? Get.arguments as Map : <String, dynamic>{};
    _latitudeController.text = '${args['latitude'] ?? ''}';
    _longitudeController.text = '${args['longitude'] ?? ''}';
    _categoryId = args['categoryId'] as int?;
    _categoryController.text = (args['categoryName'] ?? '') as String;
    _metadataTags = ((args['metadataTags'] as String?) ?? '')
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    for (final tag in _metadataTags) {
      _metadataControllers[tag] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _coverSelection.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _imageUrlController.dispose();
    _categoryController.dispose();
    for (final c in _metadataControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        leading: const SafeBackButton(),
        title: const Text('Nova pista viva'),
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          InputText(
                            hintText: 'Nome',
                            controller: _nameController,
                            validator: (v) => PValidator(
                                    [PRuleRequired(v, message: 'Obrigatório')])
                                .val(),
                          ),
                          Insets.large.height,
                          InputText(
                            hintText: 'Categoria',
                            controller: _categoryController,
                            readOnly: true,
                            validator: (_) => _categoryId == null
                                ? 'Categoria obrigatória'
                                : null,
                          ),
                          Insets.large.height,
                          RichClueEditor(onChanged: (text, delta) {
                            _descriptionController.text = text;
                            _descriptionDelta = delta;
                          }),
                          if (_metadataTags.isNotEmpty) ...[
                            Insets.large.height,
                            const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Metadata (opcional)')),
                            const SizedBox(height: 8),
                            ..._metadataTags.map((tag) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: InputText(
                                      hintText: _formatTagLabel(tag),
                                      controller: _metadataControllers[tag]!),
                                )),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          InputNumber(
                              label: 'Latitude',
                              controller: _latitudeController,
                              validator: (v) => _coordinateError(v, true)),
                          Insets.large.height,
                          InputNumber(
                              label: 'Longitude',
                              controller: _longitudeController,
                              validator: (v) => _coordinateError(v, false)),
                          Insets.large.height,
                          InputText(
                              hintText: 'URL da imagem (opcional)',
                              controller: _imageUrlController),
                          Insets.medium.height,
                          SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Ativo'),
                              value: _isActive,
                              onChanged: (v) => setState(() => _isActive = v)),
                        ],
                      ),
                    ),
                  ),
                  ClueCoverEditor(selection: _coverSelection),
                  Insets.extraLarge.height,
                  SizedBox(
                      width: double.infinity,
                      child: ActionButton(
                          theme: ActionButtonTheme.blue,
                          title: 'Salvar',
                          onPressed: _save)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_controller.isLoading.value) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    if (_categoryId == null) return;
    final metadata = <String, dynamic>{};
    for (final entry in _metadataControllers.entries) {
      final value = entry.value.text.trim();
      if (value.isNotEmpty) metadata[entry.key] = value;
    }
    final model = LivingClueModel(
      id: 0,
      name: _nameController.text.trim(),
      categoryId: _categoryId!,
      descriptionDelta: _descriptionDelta,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      latitude: latitude,
      longitude: longitude,
      imageUrl: _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim(),
      metadata: metadata.isEmpty ? null : metadata,
      isActive: _isActive,
    );
    final saved =
        _controller.savedModel != null || await _controller.save(model);
    if (saved && _controller.savedModel != null) {
      try {
        final created = _controller.savedModel!;
        // Retrying an upload keeps the existing ID while saving the current
        // form values, including edits made after the failed attempt.
        model.id = created.id;
        final currentMetadata = model.metadata ?? <String, dynamic>{};
        model.metadata = {...?created.metadata, ...currentMetadata};
        for (final key in _metadataControllers.keys) {
          if (!currentMetadata.containsKey(key)) model.metadata!.remove(key);
        }
        await _coverSelection.apply(model);
        if (_coverSelection.file != null ||
            _coverSelection.removed ||
            created.name != model.name ||
            created.description != model.description ||
            created.latitude != model.latitude ||
            created.longitude != model.longitude ||
            created.imageUrl != model.imageUrl ||
            created.isActive != model.isActive) {
          await LivingClueWebclient().update(model);
        }
      } catch (_) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'A pista foi criada, mas a capa falhou. Tente salvar novamente; a pista não será duplicada.')));
        return;
      }
    }
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  String? _coordinateError(String? text, bool latitude) {
    final other =
        latitude ? _longitudeController.text : _latitudeController.text;
    if ((text ?? '').trim().isEmpty) {
      return other.trim().isEmpty ? null : 'Informe ambas as coordenadas';
    }
    final number = double.tryParse(text!.trim());
    final limit = latitude ? 90 : 180;
    if (number == null ||
        !number.isFinite ||
        number < -limit ||
        number > limit) {
      return 'Coordenada inválida';
    }
    return null;
  }

  String _formatTagLabel(String raw) {
    final cleaned = raw.replaceAll('_', ' ');
    return cleaned
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
