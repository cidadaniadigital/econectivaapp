import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/widgets/living_clue_description_view.dart';
import 'package:unisinos_usp_app/widgets/clue_participation.dart';
import 'package:unisinos_usp_app/widgets/locker_panel.dart';
import 'package:unisinos_usp_app/services/clue_map_navigation.dart';
import 'package:unisinos_usp_app/webclients/preferences_webclient.dart';
import 'package:unisinos_usp_app/widgets/clue_content.dart';
import 'package:unisinos_usp_app/widgets/clue_connections.dart';
import 'package:unisinos_usp_app/widgets/clue_identity.dart';
import 'package:unisinos_usp_app/widgets/clue_qr_dialog.dart';
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/services/clue_return_destination.dart';
import 'package:unisinos_usp_app/widgets/clue_observations.dart';
import 'package:unisinos_usp_app/widgets/clue_attachments.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/ai_assistant_screen_context.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/services/ai_assistant_context_service.dart';
import 'package:unisinos_usp_app/widgets/action_button.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:url_launcher/url_launcher.dart';

class LivingClueShowScreen extends StatefulWidget {
  const LivingClueShowScreen({super.key});
  @override
  State<LivingClueShowScreen> createState() => _LivingClueShowScreenState();
}

class _LivingClueShowScreenState extends State<LivingClueShowScreen> {
  Future<LivingClueModel>? _clue;
  bool _canEdit = false;
  @override
  void initState() {
    super.initState();
    if (!Get.find<UserController>().isLoggedIn) {
      final destination = Uri(
          path: '/living_clues/show',
          queryParameters: {'id': Get.parameters['id'] ?? ''}).toString();
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => Get.offAllNamed(ClueReturnDestination.login(destination)));
      return;
    }
    _load();
  }

  void _load() {
    final args = Get.arguments;
    final model = args is LivingClueModel
        ? args
        : args is Map
            ? args['model']
            : null;
    final id = int.tryParse(Get.parameters['id'] ?? '') ??
        (model is LivingClueModel ? model.id : null);
    _canEdit = false;
    _clue = id == null ? null : _fetchWithPreference(id);
  }

  Future<LivingClueModel> _fetchWithPreference(int id) async {
    final results = await Future.wait<Object>([
      LivingClueWebclient().fetchById(id),
      PreferencesWebclient().editingEnabled().catchError((Object _) => false),
    ]);
    _canEdit = results[1] as bool;
    return results[0] as LivingClueModel;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<LivingClueModel>(
        future: _clue,
        builder: (context, snapshot) {
          if (snapshot.hasData)
            return _ClueDetails(
                model: snapshot.data!,
                canEdit: _canEdit,
                onEdited: () => setState(_load));
          return Scaffold(
            appBar: AppBar(
                leading: const SafeBackButton(), title: const Text('Pista')),
            body: Center(
                child: _clue == null
                    ? const Text('Selecione uma pista na listagem.')
                    : snapshot.hasError
                        ? TextButton(
                            onPressed: () => setState(_load),
                            child: const Text(
                                'Falha ao carregar pista. Tentar novamente'))
                        : const CircularProgressIndicator()),
          );
        },
      );
}

class _ClueDetails extends StatelessWidget {
  const _ClueDetails(
      {required this.model, required this.canEdit, required this.onEdited});
  final bool canEdit;
  final LivingClueModel model;
  final VoidCallback onEdited;
  @override
  Widget build(BuildContext context) {
    Get.find<AiAssistantContextService>().registerProvider(
      Get.currentRoute,
      () => _buildAiContext(model),
    );
    final bool hasValidCoordinates = model.hasLocation;
    return Scaffold(
      backgroundColor: const Color(0xFF090F20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090F20),
        foregroundColor: Colors.white,
        leading: const SafeBackButton(),
        title: const Text('Pista viva'),
        actions: [
          IconButton(
              tooltip: 'Voltar ao mapa',
              icon: const Icon(Icons.map_outlined),
              onPressed: returnToClueMap),
          LockerButton(type: 'living_clue', id: model.id),
          IconButton(
              tooltip: 'QR Code',
              icon: const Icon(Icons.qr_code),
              onPressed: () => showClueQr(context, model.id)),
          if (canEdit)
            IconButton(
              tooltip: 'Editar pista',
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Get.toNamed('/living_clues/update',
                    parameters: {'id': model.id.toString()});
                onEdited();
              },
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1232),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClueIdentity(clue: model, canEdit: canEdit),
                          LivingClueDescriptionView(
                              plainText: model.description ?? '',
                              delta: model.descriptionDelta,
                              clueId: model.id),
                          const SizedBox(height: 16),
                          ClueContent(clue: model),
                          const SizedBox(height: 16),
                          ClueConnections(clueId: model.id, canEdit: canEdit),
                          const SizedBox(height: 16),
                          ClueObservations(clue: model),
                          const SizedBox(height: 16),
                          ClueAttachments(clueId: model.id, canEdit: canEdit),
                          const SizedBox(height: 16),
                          ClueParticipation(clueId: model.id),
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Localização',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 8),
                                  if (hasValidCoordinates) ...[
                                    Text(
                                        'Lat: ${model.latitude!.toStringAsFixed(6)}'),
                                    Text(
                                        'Lng: ${model.longitude!.toStringAsFixed(6)}'),
                                  ] else
                                    const Text('Sem localização informada'),
                                  if (hasValidCoordinates) ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () async {
                                          final Uri mapsUri = Uri.parse(
                                            'https://www.google.com/maps/search/?api=1&query=${model.latitude},${model.longitude}',
                                          );
                                          final bool opened = await launchUrl(
                                            mapsUri,
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                          if (!opened) {
                                            Get.snackbar(
                                              'Erro',
                                              'Não foi possível abrir o Google Maps.',
                                              snackPosition:
                                                  SnackPosition.BOTTOM,
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.map_outlined),
                                        label: const Text('Ver no Google Maps'),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Conversa com a pista viva',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Abra um chat contextual para conversar',
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ActionButton(
                                      theme: ActionButtonTheme.blue,
                                      title: 'Conversar',
                                      icon: const Icon(Icons.forum_outlined,
                                          color: Colors.white),
                                      onPressed: () => Get.toNamed(
                                        '/living_clues/${model.id}/chat',
                                        arguments: {'model': model},
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ))),
            ),
          ),
        ],
      ),
    );
  }

  AiAssistantScreenContext _buildAiContext(LivingClueModel model) {
    return AiAssistantScreenContext(
      screenName: 'Detalhes da pista viva',
      route: '/living_clues/show?id=${model.id}',
      stage: 'consulta',
      goal:
          'inspecionar dados da pista viva e seguir para edição, mapa ou conversa',
      visibleFields: const <String>[
        'nome',
        'bioma',
        'território',
        'categoria',
        'descrição',
        'latitude',
        'longitude',
        'contexto ambiental',
        'fontes por indicador',
        'leituras recentes',
        'conexões',
      ],
      filledFields: <String, String>{
        'id': model.id.toString(),
        'nome': model.name,
        'categoria': model.category?.name ?? 'Categoria ${model.categoryId}',
      },
      notes: const <String>[
        'A tela permite abrir o chat contextual da pista viva.',
        'Quando há coordenadas válidas, a tela oferece atalho para abrir no Google Maps.',
      ],
    );
  }
}
