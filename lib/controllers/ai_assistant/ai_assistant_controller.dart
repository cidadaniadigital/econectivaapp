import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:unisinos_usp_app/models/ai_assistant_message_model.dart';
import 'package:unisinos_usp_app/services/ai_assistant_context_builder.dart';
import 'package:unisinos_usp_app/services/ai_assistant_context_service.dart';
import 'package:unisinos_usp_app/webclients/ai_assistant_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class AiAssistantController extends GetxController {
  final AiAssistantWebclient _webclient = AiAssistantWebclient();
  final AiAssistantContextService _contextService =
      Get.find<AiAssistantContextService>();

  final RxList<AiAssistantMessageModel> messages =
      <AiAssistantMessageModel>[].obs;
  final RxBool isLoadingHistory = false.obs;
  final RxBool isSending = false.obs;
  final RxBool hasLoadedHistory = false.obs;
  final RxnString errorMessage = RxnString();

  void logCurrentContext() {
    final contextData = _contextService.resolveCurrentContext();
    final context = AiAssistantContextBuilder.build(contextData);
    debugPrint(
        'AI_ASSISTANT_CONTEXT_BEGIN\n$context\nAI_ASSISTANT_CONTEXT_END');
  }

  Future<void> ensureHistoryLoaded() async {
    if (hasLoadedHistory.value || isLoadingHistory.value) return;
    await loadHistory();
  }

  Future<void> loadHistory({bool force = false}) async {
    if (isLoadingHistory.value) return;
    if (hasLoadedHistory.value && !force) return;

    try {
      isLoadingHistory.value = true;
      errorMessage.value = null;
      final List<AiAssistantMessageModel> history =
          await _webclient.fetchHistory(limit: 100, offset: 0);
      messages.assignAll(history);
      hasLoadedHistory.value = true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      errorMessage.value =
          'Não foi possível carregar o histórico do assistente.';
      Get.customSnackbar(
        'Erro',
        'Falha ao carregar histórico do assistente. $error',
      );
    } finally {
      isLoadingHistory.value = false;
    }
  }

  Future<void> sendMessage(String value) async {
    final String message = value.trim();
    if (message.isEmpty || isSending.value) return;

    messages.add(
      AiAssistantMessageModel(
        role: 'user',
        content: message,
        createdAt: DateTime.now(),
      ),
    );

    try {
      isSending.value = true;
      errorMessage.value = null;
      final contextData = _contextService.resolveCurrentContext();
      final context = AiAssistantContextBuilder.build(contextData);
      final List<AiAssistantMessageModel> returnedMessages =
          await _webclient.sendMessage(
        message: message,
        context: context,
        screenContext: AiAssistantContextBuilder.toApi(contextData),
      );

      if (returnedMessages.isEmpty) return;

      for (final item in returnedMessages) {
        final bool alreadyPresent =
            item.id != null && messages.any((msg) => msg.id == item.id);
        if (!alreadyPresent && !item.isUser) {
          messages.add(item);
        }
      }
      hasLoadedHistory.value = true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      errorMessage.value = 'Não foi possível enviar a mensagem agora.';
      Get.customSnackbar(
        'Erro',
        'Falha ao enviar mensagem para o assistente. $error',
      );
    } finally {
      isSending.value = false;
    }
  }
}
