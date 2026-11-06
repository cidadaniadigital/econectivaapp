import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/models/chat_message_model.dart';
import 'package:unisinos_usp_app/webclients/chat_webclient.dart';
import 'package:widgets_spo/utils.dart';

class ChatController extends GetxController {
  final ChatWebclient _webclient = ChatWebclient();
  final UserController _userController = Get.find<UserController>();

  final RxList<ChatMessageModel> messages = <ChatMessageModel>[].obs;
  final RxBool isSending = false.obs;
  final RxBool isLoadingHistory = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadHistory();
  }

  Future<void> sendMessage(String text, {String? fileUrl}) async {
    final String sanitized = text.trim();
    if (sanitized.isEmpty || isSending.value) return;

    messages.add(
      ChatMessageModel(
        text: sanitized,
        isUser: true,
        timestamp: DateTime.now(),
        fileUrl: fileUrl,
      ),
    );
    isSending.value = true;

    try {
      final String reply = await _webclient.sendMessage(
        message: sanitized,
        user: _userController.user.value,
        fileUrl: fileUrl,
      );

      messages.add(
        ChatMessageModel(
          text: reply,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao enviar mensagem. $error');

      messages.add(
        ChatMessageModel(
          text: 'Não foi possível enviar sua mensagem. Tente novamente.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      isSending.value = false;
    }
  }

  Future<void> _loadHistory() async {
    isLoadingHistory.value = true;
    try {
      final history = await _webclient.fetchHistory(limit: 100);
      if (history.isNotEmpty) {
        messages.assignAll(history);
      } else {
        messages.add(
          ChatMessageModel(
            text: 'Olá! Sou o assistente do UNIUSP. Como posso ajudar?',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      messages.add(
        ChatMessageModel(
          text: 'Não foi possível carregar o histórico agora.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      isLoadingHistory.value = false;
    }
  }
}
