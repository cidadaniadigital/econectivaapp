import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/node_type/node_type_create_controller.dart';
import 'package:unisinos_usp_app/controllers/node_type/node_type_index_controller.dart';
import 'package:unisinos_usp_app/controllers/node_type/node_type_update_controller.dart';

class NodeTypeIndexBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NodeTypeIndexController>(() => NodeTypeIndexController(), fenix: true);
  }
}

class NodeTypeCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NodeTypeCreateController>(() => NodeTypeCreateController(), fenix: true);
  }
}

class NodeTypeUpdateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NodeTypeUpdateController>(() => NodeTypeUpdateController(), fenix: true);
  }
}
