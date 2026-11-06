import 'package:unisinos_usp_app/services/auth_user.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'clue_return_destination.dart';
import 'package:widgets_spo/services/auth_provider.dart';
import 'package:widgets_spo/utils/util.dart';

class UserAuthService implements AuthService {
  AuthUser? _user;

  void setUser(AuthUser user) {
    _user = user;
  }

  @override
  String getToken() {
    if (_user == null || _user!.token.isEmpty) {
      throw Exception('Token inválido ou usuário não logado');
    }
    return _user!.token;
  }

  @override
  Future<void> logout() async {
    await Util.prefs.clear();
    _user = null;
    if (Get.isRegistered<UserController>())
      Get.find<UserController>().user.value = null;

    if (Get.key.currentState != null &&
        Uri.tryParse(Get.currentRoute)?.path != '/login') {
      Get.offAllNamed(ClueReturnDestination.login(Get.currentRoute));
    }
  }
}
