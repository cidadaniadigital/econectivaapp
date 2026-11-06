import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/connection_type/connection_type_create_controller.dart';
import 'package:unisinos_usp_app/controllers/connection_type/connection_type_index_controller.dart';
import 'package:unisinos_usp_app/controllers/connection_type/connection_type_update_controller.dart';

class ConnectionTypeIndexBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ConnectionTypeIndexController>(() => ConnectionTypeIndexController(), fenix: true);
  }
}

class ConnectionTypeCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ConnectionTypeCreateController>(() => ConnectionTypeCreateController(), fenix: true);
  }
}

class ConnectionTypeUpdateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ConnectionTypeUpdateController>(() => ConnectionTypeUpdateController(), fenix: true);
  }
}
