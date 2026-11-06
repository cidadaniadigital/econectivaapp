import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/ai_assistant_screen_context.dart';

typedef AiAssistantContextProvider = AiAssistantScreenContext Function();

class AiAssistantContextService extends GetxService {
  AiAssistantContextProvider? _provider;
  String? _providerRoute;
  final RxString currentRoute = ''.obs;

  void registerProvider(String route, AiAssistantContextProvider provider) {
    _provider = provider;
    _providerRoute = route;
  }

  void unregisterProvider(String route, AiAssistantContextProvider provider) {
    if (identical(_provider, provider)) {
      _provider = null;
      _providerRoute = null;
    }
  }

  void setCurrentRoute(String route) {
    currentRoute.value = route;
  }

  AiAssistantScreenContext resolveCurrentContext() {
    final route = Get.currentRoute.isNotEmpty && Get.currentRoute != '/'
        ? Get.currentRoute
        : currentRoute.value;
    final provider = _provider;
    if (provider != null &&
        _providerRoute != null &&
        Uri.tryParse(_providerRoute!)?.path == Uri.tryParse(route)?.path) {
      final context = provider();
      final requestedId =
          Uri.tryParse(route)?.queryParameters['id'] ?? Get.parameters['id'];
      final contextId = context.filledFields['id'] ??
          Uri.tryParse(context.route)?.queryParameters['id'];
      // Never reuse a loaded clue's context while another clue is loading.
      if (requestedId == null || requestedId == contextId) return context;
    }

    return AiAssistantScreenContext(
      screenName: 'Tela desconhecida',
      route: route,
      stage: 'navegação',
      goal: 'fornecer ajuda contextual ao usuário',
      notes: const <String>[
        'Nenhum contexto detalhado foi registrado para esta tela.'
      ],
    );
  }
}
