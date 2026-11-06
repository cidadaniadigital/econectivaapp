import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/category/category_update_controller.dart';

class CategoryUpdateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CategoryUpdateController>(() => CategoryUpdateController(), fenix: true);
  }
}
