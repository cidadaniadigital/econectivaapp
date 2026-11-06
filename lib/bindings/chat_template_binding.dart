import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/chat_template/chat_template_chat_controller.dart';
import 'package:unisinos_usp_app/controllers/chat_template/chat_template_create_controller.dart';
import 'package:unisinos_usp_app/controllers/chat_template/chat_template_index_controller.dart';
import 'package:unisinos_usp_app/controllers/chat_template/chat_template_source_create_controller.dart';
import 'package:unisinos_usp_app/controllers/chat_template/chat_template_update_controller.dart';

class ChatTemplateIndexBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatTemplateIndexController>(
        () => ChatTemplateIndexController(),
        fenix: true);
  }
}

class ChatTemplateChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatTemplateChatController>(() => ChatTemplateChatController(),
        fenix: true);
  }
}

class ChatTemplateCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatTemplateCreateController>(
        () => ChatTemplateCreateController(),
        fenix: true);
  }
}

class ChatTemplateUpdateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatTemplateUpdateController>(
        () => ChatTemplateUpdateController(),
        fenix: true);
  }
}

class ChatTemplateSourceCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatTemplateSourceCreateController>(
      () => ChatTemplateSourceCreateController(),
      fenix: true,
    );
  }
}
