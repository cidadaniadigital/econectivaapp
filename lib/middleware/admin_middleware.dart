import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';

class AdminMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<UserController>();
    if (!auth.isLoggedIn) return const RouteSettings(name: '/login');
    return auth.user.value?.isAdministrator == true
        ? null
        : const RouteSettings(name: '/home');
  }
}
