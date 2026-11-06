import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/chat/chat_controller.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatController>(() => ChatController(), fenix: true);
  }
}
