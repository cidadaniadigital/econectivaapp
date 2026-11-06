import 'package:get/get.dart';
import 'package:unisinos_usp_app/bindings/connection_type_binding.dart';
import 'package:unisinos_usp_app/screens/connection_type/connection_type_create_screen.dart';
import 'package:unisinos_usp_app/screens/connection_type/connection_type_index_screen.dart';
import 'package:unisinos_usp_app/screens/connection_type/connection_type_update_screen.dart';

List<GetPage> connectionTypeRoutes() => [
      GetPage(
        name: '/connection_types',
        page: () => ConnectionTypeIndexScreen(),
        binding: ConnectionTypeIndexBinding(),
      ),
      GetPage(
        name: '/connection_types/create',
        page: () => const ConnectionTypeCreateScreen(),
        binding: ConnectionTypeCreateBinding(),
      ),
      GetPage(
        name: '/connection_types/update',
        page: () => const ConnectionTypeUpdateScreen(),
        binding: ConnectionTypeUpdateBinding(),
      ),
    ];
