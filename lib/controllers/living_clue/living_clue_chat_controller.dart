import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/living_clue_chat_message_model.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/webclients/living_clue_chat_webclient.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class LivingClueChatController extends GetxController {
  LivingClueChatController();

  final LivingClueChatWebclient _chatWebclient = LivingClueChatWebclient();
  final LivingClueWebclient _livingClueWebclient = LivingClueWebclient();

  final Rxn<LivingClueModel> livingClue = Rxn<LivingClueModel>();
  final RxList<LivingClueChatMessageModel> messages =
      <LivingClueChatMessageModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isSending = false.obs;
  final RxBool hasMore = true.obs;
  final RxBool initialLoadFinished = false.obs;
  final RxInt messagesVersion = 0.obs;

  static const int pageSize = 50;

  int? livingClueId;
  String lastMutationType = 'replace';

  @override
  void onInit() {
    super.onInit();
    livingClueId = int.tryParse(Get.parameters['id'] ?? '');
    final dynamic args = Get.arguments;
    if (args is LivingClueModel) {
      livingClue.value = args;
    } else if (args is Map && args['model'] is LivingClueModel) {
      livingClue.value = args['model'] as LivingClueModel;
    }
    if (livingClueId != null) {
      loadInitial();
    }
  }

  Future<void> loadInitial() async {
    final int? id = livingClueId;
    if (id == null) return;

    try {
      isLoading.value = true;
      livingClue.value ??= await _livingClueWebclient.fetchById(id);
      final List<LivingClueChatMessageModel> fetchedMessages =
          await _chatWebclient.fetchMessages(id, limit: pageSize);
      messages.assignAll(fetchedMessages);
      hasMore.value = fetchedMessages.length == pageSize;
      _notifyMutation('replace');
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar(
          'Erro', 'Falha ao carregar conversa da pista viva. $error');
    } finally {
      isLoading.value = false;
      initialLoadFinished.value = true;
    }
  }

  Future<bool> loadOlderMessages() async {
    final int? id = livingClueId;
    if (id == null ||
        isLoading.value ||
        isLoadingMore.value ||
        !hasMore.value) {
      return false;
    }

    try {
      isLoadingMore.value = true;
      final List<LivingClueChatMessageModel> olderMessages =
          await _chatWebclient.fetchMessages(
        id,
        limit: pageSize,
        offset: messages.length,
      );

      if (olderMessages.isEmpty) {
        hasMore.value = false;
        return false;
      }

      messages.insertAll(0, olderMessages);
      hasMore.value = olderMessages.length == pageSize;
      _notifyMutation('prepend');
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao carregar mensagens antigas. $error');
      return false;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> sendMessage(String content) async {
    final int? id = livingClueId;
    final String sanitized = content.trim();
    if (id == null || sanitized.isEmpty || isSending.value) return;

    final LivingClueChatMessageModel optimisticUserMessage =
        LivingClueChatMessageModel(
      text: sanitized,
      isUser: true,
      timestamp: DateTime.now(),
      role: 'user',
      livingClueId: id,
    );

    messages.add(optimisticUserMessage);
    _notifyMutation('append');

    try {
      isSending.value = true;
      final List<LivingClueChatMessageModel> sentMessages =
          await _chatWebclient.sendMessage(id, sanitized);

      messages.remove(optimisticUserMessage);
      if (sentMessages.isNotEmpty) {
        for (final LivingClueChatMessageModel msg in sentMessages) {
          final bool alreadyExists =
              messages.any((item) => item.id != null && item.id == msg.id);
          if (!alreadyExists) {
            messages.add(msg);
          }
        }
        _notifyMutation('append');
      }
    } catch (error, stackTrace) {
      messages.remove(optimisticUserMessage);
      Util.debug(exception: error, stackTrace: stackTrace);
      if (Get.overlayContext != null || Get.context != null) {
        Get.customSnackbar('Erro', 'Falha ao enviar mensagem. $error');
      }
    } finally {
      isSending.value = false;
    }
  }

  Future<void> clearMessages() async {
    final int? id = livingClueId;
    if (id == null) return;
    try {
      isLoading.value = true;
      await _chatWebclient.deleteAllMessages(id);
      messages.clear();
      hasMore.value = false;
      _notifyMutation('replace');
      Get.successSnackbar('Conversa apagada com sucesso.');
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao limpar conversa. $error');
    } finally {
      isLoading.value = false;
    }
  }

  void _notifyMutation(String type) {
    lastMutationType = type;
    messagesVersion.value++;
  }
}
