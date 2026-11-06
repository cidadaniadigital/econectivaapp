import 'package:get/get.dart';
import 'package:unisinos_usp_app/bindings/chat_template_binding.dart';
import 'package:unisinos_usp_app/screens/chat_template/chat_template_chat_screen.dart';
import 'package:unisinos_usp_app/screens/chat_template/chat_template_create_screen.dart';
import 'package:unisinos_usp_app/screens/chat_template/chat_template_index_screen.dart';
import 'package:unisinos_usp_app/screens/chat_template/chat_template_source_create_screen.dart';
import 'package:unisinos_usp_app/screens/chat_template/chat_template_update_screen.dart';

List<GetPage> chatTemplateRoutes() => [
      GetPage(
        name: '/chat_templates',
        page: () => ChatTemplateIndexScreen(),
        binding: ChatTemplateIndexBinding(),
      ),
      GetPage(
        name: '/chat_templates/chat',
        page: () => const ChatTemplateChatScreen(),
        binding: ChatTemplateChatBinding(),
      ),
      GetPage(
        name: '/chat_templates/create',
        page: () => const ChatTemplateCreateScreen(),
        binding: ChatTemplateCreateBinding(),
      ),
      GetPage(
        name: '/chat_templates/update',
        page: () => const ChatTemplateUpdateScreen(),
        binding: ChatTemplateUpdateBinding(),
      ),
      GetPage(
        name: '/chat_templates/sources/create',
        page: () => const ChatTemplateSourceCreateScreen(),
        binding: ChatTemplateSourceCreateBinding(),
      ),
    ];
