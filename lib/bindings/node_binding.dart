import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/node/node_create_controller.dart';
import 'package:unisinos_usp_app/controllers/node/node_index_controller.dart';
import 'package:unisinos_usp_app/controllers/node/node_update_controller.dart';

class NodeIndexBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NodeIndexController>(() => NodeIndexController(), fenix: true);
  }
}

class NodeCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NodeCreateController>(() => NodeCreateController(), fenix: true);
  }
}

class NodeUpdateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NodeUpdateController>(() => NodeUpdateController(), fenix: true);
  }
}
