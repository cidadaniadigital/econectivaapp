import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/biome/biome_create_controller.dart';
import 'package:unisinos_usp_app/controllers/biome/biome_index_controller.dart';
import 'package:unisinos_usp_app/controllers/biome/biome_update_controller.dart';

class BiomeIndexBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BiomeIndexController>(
      () => BiomeIndexController(),
      fenix: true,
    );
  }
}

class BiomeCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BiomeCreateController>(
      () => BiomeCreateController(),
      fenix: true,
    );
  }
}

class BiomeUpdateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BiomeUpdateController>(
      () => BiomeUpdateController(),
      fenix: true,
    );
  }
}
