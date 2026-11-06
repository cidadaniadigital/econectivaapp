import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/user/user_create_controller.dart';
import 'package:unisinos_usp_app/controllers/user/user_index_controller.dart';
import 'package:unisinos_usp_app/controllers/user/user_update_controller.dart';

class UserIndexBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserIndexController>(() => UserIndexController(), fenix: true);
  }
}

class UserCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserCreateController>(() => UserCreateController(),
        fenix: true);
  }
}

class UserUpdateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserUpdateController>(() => UserUpdateController(),
        fenix: true);
  }
}
