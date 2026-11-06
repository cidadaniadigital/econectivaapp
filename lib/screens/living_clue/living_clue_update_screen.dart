import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/widgets/clue_cover_editor.dart';
import 'package:unisinos_usp_app/widgets/rich_clue_editor.dart';
import 'package:get/get.dart';
import 'package:pvalidator/pvalidator.dart';
import 'package:unisinos_usp_app/controllers/living_clue/living_clue_update_controller.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/widgets/action_button.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';
import 'package:widgets_spo/widgets_spo.dart';

class LivingClueUpdateScreen extends StatefulWidget {
  const LivingClueUpdateScreen({super.key});

  @override
  State<LivingClueUpdateScreen> createState() => _LivingClueUpdateScreenState();
}

class _LivingClueUpdateScreenState extends State<LivingClueUpdateScreen> {
  final LivingClueUpdateController _controller =
      Get.find<LivingClueUpdateController>();
  final _coverSelection = CoverSelection();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _categoryController = TextEditingController();
  final Map<String, TextEditingController> _metadataControllers = {};
  bool _isActive = true;
  bool _loaded = false;
  String? _descriptionDelta;

  @override
  void initState() {
    super.initState();
  }

  void _fill(LivingClueModel model) {
    if (_loaded) return;
    _nameController.text = model.name;
    _descriptionController.text = model.description ?? '';
    _descriptionDelta = model.descriptionDelta;
    _latitudeController.text = model.latitude?.toString() ?? '';
    _longitudeController.text = model.longitude?.toString() ?? '';
    _imageUrlController.text = model.imageUrl ?? '';
    _categoryController.text =
        model.category?.name ?? 'Categoria ${model.categoryId}';
    _isActive = model.isActive;
    for (final entry in (model.metadata ?? {}).entries) {
      if (const {
        'imagem_capa_arquivo_id',
        'colecao_ordem_itens_v1',
        'destaque_catalogo'
      }.contains(entry.key)) continue;
      _metadataControllers[entry.key] =
          TextEditingController(text: entry.value?.toString() ?? '');
    }
    _loaded = true;
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
    return Obx(() {
      final model = _controller.livingClue.value;
      if (_controller.isLoading.value && model == null) {
        return const Scaffold(

            body:
                Center(child: CircularProgressIndicator(color: Colors.white)));
      }
      if (model == null) {
        return const Scaffold(

            body: Center(
                child: Text('Pista não encontrada.',
                    style: TextStyle(color: Colors.white))));
      }
      _fill(model);
      return Scaffold(

        appBar: AppBar(

            foregroundColor: Colors.white,
            leading: const SafeBackButton(),
            title: const Text('Editar pista viva')),
        body: Stack(fit: StackFit.expand, children: [
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
                        child: Column(children: [
                          InputText(
                              hintText: 'Nome',
                              controller: _nameController,
                              validator: (v) => PValidator([
                                    PRuleRequired(v, message: 'Obrigatório')
                                  ]).val()),
                          Insets.large.height,
                          InputText(
                              hintText: 'Categoria',
                              controller: _categoryController,
                              readOnly: true),
                          Insets.large.height,
                          RichClueEditor(
                              key: ValueKey('description-${model.id}'),
                              plainText: model.description ?? '',
                              delta: model.descriptionDelta,
                              onChanged: (text, delta) {
                                _descriptionController.text = text;
                                _descriptionDelta = delta;
                              }),
                          if (_metadataControllers.isNotEmpty) ...[
                            Insets.large.height,
                            const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Metadata (opcional)')),
                            const SizedBox(height: 8),
                            ..._metadataControllers.entries.map((entry) =>
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: InputText(
                                        hintText: _formatTagLabel(entry.key),
                                        controller: entry.value))),
                          ],
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(children: [
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
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _selectPointOnMap,
                              icon: const Icon(Icons.map_outlined),
                              label: const Text(
                                'Selecionar latitude/longitude no mapa',
                              ),
                            ),
                          ),
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
                        ]),
                      ),
                    ),
                    ClueCoverEditor(selection: _coverSelection),
                    Insets.extraLarge.height,
                    SizedBox(
                        width: double.infinity,
                        child: ActionButton(
                            theme: ActionButtonTheme.blue,
                            title: 'Salvar',
                            onPressed: () => _save(model))),
                  ]),
            ),
          )
        ]),
      );
    });
  }

  Future<void> _save(LivingClueModel original) async {
    if (_controller.isLoading.value) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());

    final metadata = Map<String, dynamic>.from(original.metadata ?? {});
    for (final entry in _metadataControllers.entries) {
      final value = entry.value.text.trim();
      if (value == (original.metadata?[entry.key]?.toString() ?? '')) continue;
      if (value.isEmpty) {
        metadata.remove(entry.key);
      } else {
        metadata[entry.key] = value;
      }
    }
    final updated = LivingClueModel(
      id: original.id,
      name: _nameController.text.trim(),
      categoryId: original.categoryId,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      descriptionDelta: _descriptionDelta,
      removeLocation: latitude == null && longitude == null,
      latitude: latitude,
      longitude: longitude,
      imageUrl: _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim(),
      metadata: metadata.isEmpty ? null : metadata,
      isActive: _isActive,
    );
    try {
      await _coverSelection.apply(updated);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Falha no envio da capa. Suas alterações continuam no formulário.')));
      return;
    }
    final saved = await _controller.save(updated);
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _selectPointOnMap() async {
    final double? currentLatitude =
        double.tryParse(_latitudeController.text.trim());
    final double? currentLongitude =
        double.tryParse(_longitudeController.text.trim());

    final dynamic result = await Get.toNamed(
      '/map/point_picker',
      arguments: {
        'title': 'Selecionar localização da pista viva',
        if (currentLatitude != null) 'latitude': currentLatitude,
        if (currentLongitude != null) 'longitude': currentLongitude,
      },
    );

    if (result is! Map) return;
    final dynamic latitude = result['latitude'];
    final dynamic longitude = result['longitude'];
    if (latitude is! num || longitude is! num) return;

    _latitudeController.text = latitude.toStringAsFixed(6);
    _longitudeController.text = longitude.toStringAsFixed(6);
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
