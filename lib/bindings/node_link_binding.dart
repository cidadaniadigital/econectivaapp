import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/node_link/node_link_create_controller.dart';
import 'package:unisinos_usp_app/controllers/node_link/node_link_index_controller.dart';
import 'package:unisinos_usp_app/controllers/node_link/node_link_update_controller.dart';

class NodeLinkIndexBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NodeLinkIndexController>(() => NodeLinkIndexController(), fenix: true);
  }
}

class NodeLinkCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NodeLinkCreateController>(() => NodeLinkCreateController(), fenix: true);
  }
}

class NodeLinkUpdateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NodeLinkUpdateController>(() => NodeLinkUpdateController(), fenix: true);
  }
}
