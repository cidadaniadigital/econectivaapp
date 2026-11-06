import 'package:get/get.dart';
import 'package:unisinos_usp_app/bindings/node_binding.dart';
import 'package:unisinos_usp_app/bindings/node_graph_binding.dart';
import 'package:unisinos_usp_app/screens/node/node_create_screen.dart';
import 'package:unisinos_usp_app/screens/node/node_index_screen.dart';
import 'package:unisinos_usp_app/screens/node/node_update_screen.dart';
import 'package:unisinos_usp_app/screens/node_graph/node_graph_screen.dart';

List<GetPage> nodeRoutes() => [
      GetPage(
        name: '/nodes',
        page: () => NodeIndexScreen(),
        binding: NodeIndexBinding(),
      ),
      GetPage(
        name: '/nodes/create',
        page: () => const NodeCreateScreen(),
        binding: NodeCreateBinding(),
      ),
      GetPage(
        name: '/nodes/update',
        page: () => const NodeUpdateScreen(),
        binding: NodeUpdateBinding(),
      ),
      GetPage(
        name: '/nodes/graph',
        page: () => const NodeGraphScreen(),
        binding: NodeGraphBinding(),
      ),
    ];
