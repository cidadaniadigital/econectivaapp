import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pvalidator/pvalidator.dart';
import 'package:unisinos_usp_app/models/ai_assistant_screen_context.dart';
import 'package:unisinos_usp_app/models/category_model.dart';
import 'package:unisinos_usp_app/services/ai_assistant_context_service.dart';
import 'package:unisinos_usp_app/webclients/category_select_webclient.dart';
import 'package:unisinos_usp_app/webclients/category_webclient.dart';
import 'package:unisinos_usp_app/widgets/action_button.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';
import 'package:widgets_spo/widgets_spo.dart';

class LivingCluePreCreateScreen extends StatefulWidget {
  const LivingCluePreCreateScreen({super.key});

  @override
  State<LivingCluePreCreateScreen> createState() =>
      _LivingCluePreCreateScreenState();
}

class _LivingCluePreCreateScreenState extends State<LivingCluePreCreateScreen> {
  static const String _screenName = 'Escolha da categoria';
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ItemSelectController _categorySelectController = ItemSelectController();
  String? _selectedType;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      _selectedType = args['type'] as String?;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Get.find<AiAssistantContextService>().registerProvider(
      Get.currentRoute,
      _buildAiContext,
    );
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        leading: const SafeBackButton(),
        title: const Text('Escolha a categoria'),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.category_outlined,
                                  color: Colors.indigo),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedType == null
                                      ? 'Selecione a categoria base'
                                      : 'Selecione a categoria base de $_selectedType',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedType == null
                                ? 'Os campos dinâmicos e o visual da pista seguirão a categoria escolhida.'
                                : 'Serão exibidas apenas categorias do tipo $_selectedType.',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          Insets.large.height,
                          InputSelectApi(
                            label: 'Categoria',
                            controller: _categorySelectController,
                            validator: (value) => PValidator([
                              PRuleRequired(value, message: 'Obrigatório'),
                            ]).val(),
                            onFind: (search, offset, params) =>
                                CategorySelectWebclient().select(search, offset,
                                    type: _selectedType),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Insets.extraLarge.height,
                  SizedBox(
                    width: double.infinity,
                    child: ActionButton(
                      theme: ActionButtonTheme.blue,
                      title: _loading ? 'Carregando...' : 'Continuar',
                      onPressed: _loading ? null : _continue,
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

  AiAssistantScreenContext _buildAiContext() {
    return AiAssistantScreenContext(
      screenName: _screenName,
      route: Get.currentRoute,
      stage: 'pré-cadastro da pista',
      goal: 'selecionar a categoria base para definir os campos do formulário',
      visibleFields: const <String>[
        'categoria',
        'tipo',
        'continuar',
      ],
      filledFields: <String, String>{
        'tipo selecionado': _selectedType ?? 'nenhum',
        'categoria selecionada':
            _categorySelectController.selectedItem?.name ?? 'nenhuma',
      },
      notes: const <String>[
        'A categoria escolhida define os campos dinâmicos e o visual da pista.',
      ],
    );
  }

  Future<void> _continue() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final int? categoryId = _categorySelectController.selectedItem?.id;
    final String? categoryName = _categorySelectController.selectedItem?.name;
    if (categoryId == null || categoryName == null) return;

    setState(() => _loading = true);
    try {
      final CategoryModel category =
          await CategoryWebclient().fetchById(categoryId);
      final args = Get.arguments;
      final result = await Get.toNamed(
        '/living_clues/create',
        arguments: {
          'categoryId': category.id,
          'categoryName': category.name,
          'categoryType': category.type,
          'metadataTags': category.metadataTags,
          if (args is Map && args['latitude'] != null)
            'latitude': args['latitude'],
          if (args is Map && args['longitude'] != null)
            'longitude': args['longitude'],
        },
      );
      if (result == true) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      Get.snackbar(
          'Categoria', 'Não foi possível carregar a categoria selecionada.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
