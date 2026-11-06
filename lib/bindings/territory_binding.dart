import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/territory/territory_create_controller.dart';
import 'package:unisinos_usp_app/controllers/territory/territory_index_controller.dart';
import 'package:unisinos_usp_app/controllers/territory/territory_update_controller.dart';

class TerritoryIndexBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TerritoryIndexController>(
      () => TerritoryIndexController(),
      fenix: true,
    );
  }
}

class TerritoryCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TerritoryCreateController>(
      () => TerritoryCreateController(),
      fenix: true,
    );
  }
}

class TerritoryUpdateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TerritoryUpdateController>(
      () => TerritoryUpdateController(),
      fenix: true,
    );
  }
}
