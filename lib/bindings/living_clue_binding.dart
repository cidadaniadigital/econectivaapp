import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/living_clue/environmental_layers_controller.dart';
import 'package:unisinos_usp_app/controllers/living_clue/living_clue_chat_controller.dart';
import 'package:unisinos_usp_app/controllers/living_clue/living_clue_create_controller.dart';
import 'package:unisinos_usp_app/controllers/living_clue/living_clue_index_controller.dart';
import 'package:unisinos_usp_app/controllers/living_clue/living_clue_map_controller.dart';
import 'package:unisinos_usp_app/controllers/living_clue/living_clue_update_controller.dart';

class LivingClueIndexBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LivingClueIndexController>(() => LivingClueIndexController(),
        fenix: true);
  }
}

class LivingClueCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LivingClueCreateController>(() => LivingClueCreateController(),
        fenix: true);
  }
}

class LivingClueUpdateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LivingClueUpdateController>(() => LivingClueUpdateController(),
        fenix: true);
  }
}

class LivingClueMapBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EnvironmentalLayersController>(
        () => EnvironmentalLayersController(),
        fenix: true);
    Get.lazyPut<LivingClueMapController>(() => LivingClueMapController(),
        fenix: true);
  }
}

class LivingClueChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LivingClueChatController>(() => LivingClueChatController(),
        fenix: true);
  }
}
