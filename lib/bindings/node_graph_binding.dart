import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/node_graph/node_graph_controller.dart';

class NodeGraphBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NodeGraphController>(() => NodeGraphController(), fenix: true);
  }
}
