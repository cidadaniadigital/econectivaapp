import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/clue_connection/clue_connection_create_controller.dart';
import 'package:unisinos_usp_app/controllers/clue_connection/clue_connection_index_controller.dart';
import 'package:unisinos_usp_app/controllers/clue_connection/clue_connection_update_controller.dart';

class ClueConnectionIndexBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ClueConnectionIndexController>(() => ClueConnectionIndexController(), fenix: true);
  }
}

class ClueConnectionCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ClueConnectionCreateController>(() => ClueConnectionCreateController(), fenix: true);
  }
}

class ClueConnectionUpdateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ClueConnectionUpdateController>(() => ClueConnectionUpdateController(), fenix: true);
  }
}
