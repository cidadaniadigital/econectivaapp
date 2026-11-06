import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/user_model.dart';
import 'package:unisinos_usp_app/utils/safe_get_snackbar.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class UserUpdateController extends GetxController {
  final UserWebclient _webclient = UserWebclient();

  final Rxn<UserModel> user = Rxn<UserModel>();
  final RxBool isLoading = false.obs;

  int? userId;

  @override
  void onInit() {
    super.onInit();
    userId = int.tryParse(Get.parameters['id'] ?? '');
    if (userId != null) {
      loadUser(userId!);
    }
  }

  Future<void> loadUser(int id) async {
    try {
      isLoading.value = true;
      user.value = await _webclient.fetchUserById(id);
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível carregar o usuário.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> save(UserModel model) async {
    final int? id = model.id == 0 ? user.value?.id ?? userId : model.id;
    if (id == null) return false;

    model.id = id;

    try {
      isLoading.value = true;
      await _webclient.updateUser(model);
      SafeGetSnackbar.success('Usuário atualizado com sucesso.');
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível atualizar o usuário.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
