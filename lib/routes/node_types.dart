import 'package:get/get.dart';
import 'package:unisinos_usp_app/bindings/node_type_binding.dart';
import 'package:unisinos_usp_app/screens/node_type/node_type_create_screen.dart';
import 'package:unisinos_usp_app/screens/node_type/node_type_index_screen.dart';
import 'package:unisinos_usp_app/screens/node_type/node_type_update_screen.dart';

List<GetPage> nodeTypeRoutes() => [
      GetPage(
        name: '/node_types',
        page: () => NodeTypeIndexScreen(),
        binding: NodeTypeIndexBinding(),
      ),
      GetPage(
        name: '/node_types/create',
        page: () => const NodeTypeCreateScreen(),
        binding: NodeTypeCreateBinding(),
      ),
      GetPage(
        name: '/node_types/update',
        page: () => const NodeTypeUpdateScreen(),
        binding: NodeTypeUpdateBinding(),
      ),
    ];
