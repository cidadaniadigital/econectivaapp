import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/chat_message_model.dart';
import 'package:unisinos_usp_app/models/chat_template_model.dart';
import 'package:unisinos_usp_app/webclients/chat_template_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class ChatTemplateChatController extends GetxController {
  ChatTemplateChatController();

  final ChatTemplateWebclient _webclient = ChatTemplateWebclient();

  final Rxn<ChatTemplateModel> template = Rxn<ChatTemplateModel>();
  final RxList<ChatMessageModel> messages = <ChatMessageModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isSending = false.obs;
  final RxBool hasMore = true.obs;
  final RxBool initialLoadFinished = false.obs;
  final RxInt messagesVersion = 0.obs;

  static const int pageSize = 50;

  int? templateId;
  String lastMutationType = 'replace';

  @override
  void onInit() {
    super.onInit();
    templateId = int.tryParse(Get.parameters['id'] ?? '');
    final dynamic args = Get.arguments;
    if (args is ChatTemplateModel) {
      template.value = args;
    }
    templateId ??= template.value?.id;
    if (templateId != null) {
      loadInitial();
    }
  }

  Future<void> loadInitial() async {
    final int? id = templateId;
    if (id == null) return;

    try {
      isLoading.value = true;
      template.value ??= await _webclient.fetchById(id);
      final List<ChatMessageModel> fetchedMessages =
          await _webclient.fetchMessages(id, limit: pageSize, offset: 0);
      messages.assignAll(fetchedMessages);
      hasMore.value = fetchedMessages.length == pageSize;
      _notifyMutation('replace');
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar(
          'Erro', 'Falha ao carregar conversa do template. $error');
    } finally {
      isLoading.value = false;
      initialLoadFinished.value = true;
    }
  }

  Future<bool> loadOlderMessages() async {
    final int? id = templateId;
    if (id == null || isLoading.value || isLoadingMore.value || !hasMore.value)
      return false;

    try {
      isLoadingMore.value = true;
      final List<ChatMessageModel> olderMessages =
          await _webclient.fetchMessages(
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
    final int? id = templateId;
    final String sanitized = content.trim();
    if (id == null || sanitized.isEmpty || isSending.value) return;

    final ChatMessageModel optimisticUserMessage = ChatMessageModel(
      text: sanitized,
      isUser: true,
      timestamp: DateTime.now(),
      role: 'user',
    );

    messages.add(optimisticUserMessage);
    _notifyMutation('append');

    try {
      isSending.value = true;
      final List<ChatMessageModel> sentMessages =
          await _webclient.sendMessage(id, sanitized);

      messages.remove(optimisticUserMessage);

      if (sentMessages.isNotEmpty) {
        for (final ChatMessageModel msg in sentMessages) {
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

  void _notifyMutation(String type) {
    lastMutationType = type;
    messagesVersion.value++;
  }
}
