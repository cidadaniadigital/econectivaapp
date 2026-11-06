import 'package:unisinos_usp_app/services/modal_route_observer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/ai_assistant/ai_assistant_controller.dart';
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/services/ai_assistant_context_service.dart';
import 'package:unisinos_usp_app/widgets/ai_assistant_panel.dart';

class AiAssistantLauncher extends StatelessWidget {
  const AiAssistantLauncher({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final UserController userController = Get.find<UserController>();
    final AiAssistantController controller = Get.find<AiAssistantController>();
    final AiAssistantContextService contextService =
        Get.find<AiAssistantContextService>();

    return Obx(() {
      final String route = contextService.currentRoute.value.isEmpty
          ? Get.currentRoute
          : contextService.currentRoute.value;
      final String routingCurrent = Get.routing.current;
      final bool isLivingClueChatRoute = route == '/living_clues/:id/chat' ||
          (route.startsWith('/living_clues/') && route.endsWith('/chat')) ||
          routingCurrent == '/living_clues/:id/chat' ||
          (routingCurrent.startsWith('/living_clues/') &&
              routingCurrent.endsWith('/chat'));
      final bool isChatTemplateChatRoute =
          route.startsWith('/chat_templates/chat') ||
              routingCurrent.startsWith('/chat_templates/chat');
      final bool isLegacyChatRoute = Uri.tryParse(route)?.path == '/chat' ||
          Uri.tryParse(routingCurrent)?.path == '/chat';

      final bool showLauncher = userController.isLoggedIn &&
          !ModalRouteObserver.instance.popupVisible.value &&
          route != '/splash' &&
          !route.startsWith('/login') &&
          !route.startsWith('/create_account') &&
          !route.startsWith('/password_recover') &&
          !route.startsWith('/recover_password') &&
          !route.startsWith('/password_recovery') &&
          !route.startsWith('/code_confirmation') &&
          !route.startsWith('/create_password') &&
          !isLivingClueChatRoute &&
          !isChatTemplateChatRoute &&
          !isLegacyChatRoute;

      return Stack(
        children: [
          child,
          if (showLauncher)
            Positioned(
              right: 16,
              bottom: 24,
              child: FloatingActionButton.extended(
                heroTag: 'ai-assistant-launcher',
                isExtended: MediaQuery.sizeOf(context).width >= 600,
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                onPressed: () {
                  contextService.setCurrentRoute(Get.currentRoute);
                  controller.logCurrentContext();
                  final BuildContext? navigatorContext =
                      Get.key.currentContext ?? Get.overlayContext;
                  if (navigatorContext == null) return;
                  showModalBottomSheet<void>(
                    context: navigatorContext,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AiAssistantPanel(),
                  );
                  controller.ensureHistoryLoaded();
                },
                icon: const Icon(Icons.auto_awesome,
                    semanticLabel: 'Assistente IA'),
                label: const Text('Assistente IA'),
              ),
            ),
        ],
      );
    });
  }
}
