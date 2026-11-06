import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/user_model.dart';
import 'package:unisinos_usp_app/utils/safe_get_snackbar.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class UserCreateController extends GetxController {
  final UserWebclient _webclient = UserWebclient();

  final RxBool isLoading = false.obs;

  Future<bool> save(UserModel model) async {
    try {
      isLoading.value = true;
      await _webclient.createUser(model);
      SafeGetSnackbar.success('Usuário salvo com sucesso.');
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível salvar o usuário.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
