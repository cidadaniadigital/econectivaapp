import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/auth/profile_controller.dart';
import 'package:unisinos_usp_app/screens/screens.dart';

List<GetPage> authRoutes() => [
      GetPage(name: '/login', page: () => const LoginScreen()),
      GetPage(name: '/create_account', page: () => CreateAccountScreen()),
      GetPage(name: '/recover_password', page: () => RecoverPasswordScreen()),
      GetPage(
          name: '/code_confirmation',
          page: () => const CodeConfirmationScreen()),
      GetPage(
          name: '/password_recovery/:token',
          page: () => CreatePasswordScreen()),
      GetPage(name: '/create_password', page: () => CreatePasswordScreen()),
      GetPage(
        name: '/profile',
        page: () => const ProfileScreen(),
        binding: BindingsBuilder(() {
          Get.lazyPut<ProfileController>(() => ProfileController(),
              fenix: true);
        }),
      ),
    ];
