import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/models/user_model.dart';
import 'package:unisinos_usp_app/services/auth_user.dart';
import 'package:unisinos_usp_app/utils/safe_get_snackbar.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class ProfileController extends GetxController {
  ProfileController({
    UserWebclient? webclient,
    UserController? userController,
  })  : _webclient = webclient ?? UserWebclient(),
        _userController = userController ?? Get.find<UserController>();

  final UserWebclient _webclient;
  final UserController _userController;

  final Rxn<UserModel> user = Rxn<UserModel>();
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  int? get loggedUserId => _userController.user.value?.id;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final int? id = loggedUserId;
    if (id == null) {
      SafeGetSnackbar.error('Erro', 'Usuário não autenticado.');
      return;
    }

    try {
      isLoading.value = true;
      user.value = await _webclient.fetchUserById(id);
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível carregar seu perfil.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveProfile({
    required String name,
    required String email,
    String? phone,
    String? password,
  }) async {
    final current = user.value;
    if (current == null) return false;

    final model = UserModel(
      id: current.id,
      name: name,
      email: email,
      profile: current.profile,
      phone: phone,
      password: password,
    );

    try {
      isSaving.value = true;
      final updated = await _webclient.updateUser(model);
      user.value = updated;

      final authUser = _userController.user.value;
      if (authUser != null) {
        await _userController.savePrefs(
          AuthUser(
            id: authUser.id,
            name: updated.name,
            email: updated.email,
            token: authUser.token,
            profile: updated.profile,
          ),
        );
      }

      SafeGetSnackbar.success('Perfil atualizado com sucesso.');
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível atualizar seu perfil.');
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
