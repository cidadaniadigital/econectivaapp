import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pvalidator/pvalidator.dart';
import 'package:unisinos_usp_app/models/ai_assistant_screen_context.dart';
import 'package:unisinos_usp_app/models/category_model.dart';
import 'package:unisinos_usp_app/webclients/category_webclient.dart';
import 'package:unisinos_usp_app/services/ai_assistant_context_service.dart';
import 'package:unisinos_usp_app/widgets/action_button.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';
import 'package:widgets_spo/widgets_spo.dart';

class LivingClueTypeSelectScreen extends StatefulWidget {
  const LivingClueTypeSelectScreen({super.key});

  @override
  State<LivingClueTypeSelectScreen> createState() =>
      _LivingClueTypeSelectScreenState();
}

class _LivingClueTypeSelectScreenState
    extends State<LivingClueTypeSelectScreen> {
  static const String _screenName = 'Escolha do tipo da pista';
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _selectedType;
  List<String> _types = CategoryType.values;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    try {
      final categories = await CategoryWebclient().fetch();
      if (!mounted) return;
      setState(() => _types = {
            ...CategoryType.values,
            ...categories
                .map((category) => category.type)
                .where((type) => type.isNotEmpty)
          }.toList());
    } catch (_) {
      if (mounted)
        Get.snackbar('Categorias',
            'Não foi possível carregar os tipos. Tente novamente.');
    }
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
        title: const Text('Escolha o tipo da pista'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            child: Form(
              key: _formKey,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.alt_route_outlined,
                              color: Colors.indigo),
                          const SizedBox(width: 8),
                          Text(
                            'Defina o tipo da pista',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'A proxima etapa exibira apenas categorias compativeis com o tipo selecionado.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      Insets.large.height,
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo',
                          border: OutlineInputBorder(),
                        ),
                        items: _types
                            .map(
                              (type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedType = value);
                        },
                        validator: (value) => PValidator([
                          PRuleRequired(value, message: 'Obrigatorio'),
                        ]).val(),
                      ),
                      Insets.extraLarge.height,
                      SizedBox(
                        width: double.infinity,
                        child: ActionButton(
                          theme: ActionButtonTheme.blue,
                          title: 'Continuar',
                          onPressed: _continue,
                        ),
                      ),
                    ],
                  ),
                ),
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
      stage: 'pre-cadastro da pista',
      goal: 'selecionar o tipo da pista antes da categoria',
      visibleFields: const <String>[
        'tipo',
        'continuar',
      ],
      filledFields: <String, String>{
        'tipo selecionado': _selectedType ?? 'nenhum',
      },
      notes: const <String>[
        'O tipo define quais categorias serao exibidas na proxima tela.',
      ],
    );
  }

  Future<void> _continue() async {
    if (!(_formKey.currentState?.validate() ?? false) ||
        _selectedType == null) {
      return;
    }

    final args = Get.arguments;
    final result = await Get.toNamed(
      '/living_clues/pre_create',
      arguments: <String, dynamic>{
        'type': _selectedType,
        if (args is Map && args['latitude'] != null)
          'latitude': args['latitude'],
        if (args is Map && args['longitude'] != null)
          'longitude': args['longitude'],
      },
    );
    if (result == true) {
      Navigator.of(context).pop(true);
    }
  }
}
