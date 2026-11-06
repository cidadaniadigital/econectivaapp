import 'package:get/get.dart';
import 'package:unisinos_usp_app/bindings/node_link_binding.dart';
import 'package:unisinos_usp_app/screens/node_link/node_link_create_screen.dart';
import 'package:unisinos_usp_app/screens/node_link/node_link_index_screen.dart';
import 'package:unisinos_usp_app/screens/node_link/node_link_update_screen.dart';

List<GetPage> nodeLinkRoutes() => [
      GetPage(
        name: '/node_links',
        page: () => NodeLinkIndexScreen(),
        binding: NodeLinkIndexBinding(),
      ),
      GetPage(
        name: '/node_links/create',
        page: () => const NodeLinkCreateScreen(),
        binding: NodeLinkCreateBinding(),
      ),
      GetPage(
        name: '/node_links/update',
        page: () => const NodeLinkUpdateScreen(),
        binding: NodeLinkUpdateBinding(),
      ),
    ];
