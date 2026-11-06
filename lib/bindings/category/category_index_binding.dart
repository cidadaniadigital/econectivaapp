import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/category/category_index_controller.dart';

class CategoryIndexBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CategoryIndexController>(() => CategoryIndexController(), fenix: true);
  }
}
