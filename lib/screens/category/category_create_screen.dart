import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/widgets/category_icon_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:pvalidator/pvalidator.dart';
import 'package:unisinos_usp_app/controllers/category/category_create_controller.dart';
import 'package:unisinos_usp_app/models/category_model.dart';
import 'package:unisinos_usp_app/widgets/action_button.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';
import 'package:widgets_spo/widgets_spo.dart';

class CategoryCreateScreen extends StatefulWidget {
  const CategoryCreateScreen({super.key});

  @override
  State<CategoryCreateScreen> createState() => _CategoryCreateScreenState();
}

class _CategoryCreateScreenState extends State<CategoryCreateScreen> {
  final CategoryCreateController _controller =
      Get.find<CategoryCreateController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _colorController =
      TextEditingController(text: '#');
  final TextEditingController _iconController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _metadataTagsController = TextEditingController();
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _colorController.addListener(_onColorTextChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.removeListener(_onColorTextChanged);
    _colorController.dispose();
    _iconController.dispose();
    _descriptionController.dispose();
    _metadataTagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        leading: const SafeBackButton(),
        title: const Text('Nova categoria'),
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
                  InputText(
                    hintText: 'Nome',
                    controller: _nameController,
                    validator: (value) => PValidator([
                      PRuleRequired(value, message: 'Obrigatório'),
                      PRuleMaxString(value, 255,
                          message: 'Máximo de 255 caracteres'),
                    ]).val(),
                  ),
                  Insets.large.height,
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    items: CategoryType.values
                        .map(
                          (type) => DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _selectedType = value),
                    validator: (value) => PValidator([
                      PRuleRequired(value, message: 'Obrigatório'),
                    ]).val(),
                  ),
                  Insets.large.height,
                  InputText(
                    hintText: 'Cor em hex (ex: #FF5733)',
                    controller: _colorController,
                    validator: (value) => PValidator([
                      PRuleRequired(value, message: 'Obrigatório'),
                      PRuleRegex(value, r'^#([A-Fa-f0-9]{6})$',
                          message: 'Use o formato #RRGGBB'),
                    ]).val(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: _openColorPicker,
                        icon: const Icon(Icons.color_lens_outlined),
                        label: const Text('Selecionar cor'),
                      ),
                    ],
                  ),
                  Insets.large.height,
                  InputText(
                    hintText: 'Código do ícone (opcional)',
                    controller: _iconController,
                  ),
                  CategoryIconPicker(
                      controller: _iconController,
                      name: _nameController.text,
                      type: _selectedType ?? '',
                      color: _selectedColor),
                  Insets.large.height,
                  InputText(
                    hintText: 'Descrição (opcional)',
                    controller: _descriptionController,
                    maxLines: 4,
                  ),
                  Insets.large.height,
                  InputText(
                    hintText: 'Metadata tags (ex: tag_teste,tag_other)',
                    controller: _metadataTagsController,
                    validator: (value) => PValidator([
                      PRuleRequired(value, message: 'Obrigatório'),
                      PRuleRegex(
                        value,
                        r'^[A-Za-z0-9_]+(,[A-Za-z0-9_]+)*$',
                        message:
                            'Use somente letras/números/_ separados por vírgula, sem espaços',
                      ),
                    ]).val(),
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

  void _onColorTextChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Color get _selectedColor => _parseHexColor(_colorController.text);

  Color _parseHexColor(String value) {
    try {
      final String sanitized = value.trim().replaceFirst('#', '');
      if (sanitized.length == 6) {
        return Color(int.parse('0xff$sanitized'));
      }
    } catch (_) {
      // ignore parsing errors and fall back to blue
    }
    return Colors.blue;
  }

  String _colorToHex(Color color) {
    final String hex =
        color.value.toRadixString(16).padLeft(8, '0').substring(2);
    return '#${hex.toUpperCase()}';
  }

  Future<void> _openColorPicker() async {
    Color tempColor = _selectedColor;

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Selecione uma cor'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: tempColor,
            onColorChanged: (color) => tempColor = color,
            enableAlpha: false,
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _colorController.text = _colorToHex(tempColor);
              Navigator.of(context).pop();
            },
            child: const Text('Selecionar'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final bool saved = await _controller.save(
      name: _nameController.text,
      type: _selectedType ?? '',
      colorHex: _colorController.text,
      iconCode: _iconController.text,
      description: _descriptionController.text,
      metadataTags: _metadataTagsController.text,
    );
    if (saved) {
      Get.secureBack(result: true);
    }
  }
}
