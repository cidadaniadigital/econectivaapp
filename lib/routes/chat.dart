import 'package:get/get.dart';
import 'package:unisinos_usp_app/bindings/chat_binding.dart';
import 'package:unisinos_usp_app/screens/chat/chat_screen.dart';

List<GetPage> chatRoutes() => [
      GetPage(
        name: '/chat',
        page: () => const ChatScreen(),
        binding: ChatBinding(),
      ),
    ];
