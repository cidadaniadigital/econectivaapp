import 'dart:convert';
import 'package:unisinos_usp_app/services/clue_return_destination.dart';

import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:unisinos_usp_app/services/auth_user.dart';
import 'package:unisinos_usp_app/services/google_auth_service.dart';
import 'package:unisinos_usp_app/services/user_auth_service.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:widgets_spo/services/auth_provider.dart';
import 'package:widgets_spo/utils.dart';

class UserController extends GetxController {
  UserWebclient webclient = UserWebclient();
  Rxn<AuthUser> user = Rxn<AuthUser>();

  @override
  void onInit() {
    super.onInit();
    initializeUser();
  }

  bool get isLoggedIn => user.value != null;

  Future<void> initializeUser() async {
    final String? userPref = Util.prefs.getString('user');

    if (userPref != null) {
      AuthUser localUser = AuthUser.fromJson(jsonDecode(userPref));

      user.value = localUser;
      (AuthProvider.instance as UserAuthService).setUser(user.value!);
      if (localUser.profile == null) {
        try {
          final current = await webclient.fetchUserById(localUser.id);
          await savePrefs(AuthUser(
              id: localUser.id,
              name: current.name,
              email: current.email,
              token: localUser.token,
              profile: current.profile));
        } catch (_) {
          /* Keep the session; the API remains authoritative for permissions. */
        }
      }
    } else {
      user.value = null;
    }
  }

  void redirectLoggedUser() {
    final bool loggedIn = user.value != null;
    Get.offAllNamed(loggedIn ? '/home' : '/login');
  }

  /// @method
  Future<void> login(String mail, String password) async {
    try {
      AuthUser loggedUser =
          await webclient.login(mail: mail, password: password);
      await savePrefs(loggedUser);
      Get.offAllNamed(
          ClueReturnDestination.validate(Get.parameters['return']) ?? '/home');
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao realizar login. $error');
      rethrow;
    }
  }

  Future<void> loginGoogle() async {
    try {
      final GoogleAuthService authService = GoogleAuthService();

      await authService.signOut();

      final GoogleSignInAccount? googleUser =
          await authService.signInWithGoogle();

      if (googleUser != null) {
        final GoogleSignInAuthentication auth = await googleUser.authentication;

        AuthUser loggedUser = await webclient.loginGoogle(
            auth.idToken ?? '', auth.accessToken ?? '');

        await savePrefs(loggedUser);

        Get.offAllNamed(
            ClueReturnDestination.validate(Get.parameters['return']) ??
                '/home');
      }
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Erro ao logar com Google. $error');
      rethrow;
    }
  }

  Future<bool> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await webclient.register(name: name, email: email, password: password);

      Get.successSnackbar('Usuário registrado com sucesso!'.tlt);
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao criar usuário. $error');
      rethrow;
    }
  }

  Future<bool> sendCode(String email) async {
    try {
      await webclient.forgotPassword(email);
      Get.successSnackbar(
        'Se o email estiver registrado em nossa base, iremos enviar um link de recuperação de senha para você!'
            .tlt,
        duration: const Duration(seconds: 5),
      );
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Erro ao enviar email. $error');
      rethrow;
    }
  }

  Future<AuthUser> recoverPassword(String token, String password) async {
    try {
      user.value = await webclient.recoverPassword(token, password);
      Get.successSnackbar('Senha alterada com sucesso!'.tlt);
      return user.value!;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Erro ao alterar a senha. $error');
      rethrow;
    }
  }

  Future<void> logout() async {
    user.value = null;
    await AuthProvider.instance.logout();
  }

  Future<void> savePrefs(AuthUser loggedUser) async {
    await Util.prefs.setString('user', jsonEncode(loggedUser.toJson()));
    (AuthProvider.instance as UserAuthService).setUser(loggedUser);

    user.value = loggedUser;
  }
}
