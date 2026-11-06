import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/category/category_create_controller.dart';

class CategoryCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CategoryCreateController>(() => CategoryCreateController(), fenix: true);
  }
}
