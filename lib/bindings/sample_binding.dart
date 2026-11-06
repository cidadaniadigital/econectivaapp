import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/sample/sample_create_controller.dart';
import 'package:unisinos_usp_app/controllers/sample/sample_index_controller.dart';
import 'package:unisinos_usp_app/controllers/sample/sample_update_controller.dart';

class SampleIndexBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SampleIndexController>(() => SampleIndexController(), fenix: true);
  }
}

class SampleCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SampleCreateController>(() => SampleCreateController(), fenix: true);
  }
}

class SampleUpdateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SampleUpdateController>(() => SampleUpdateController(), fenix: true);
  }
}
