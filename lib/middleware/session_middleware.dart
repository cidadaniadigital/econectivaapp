import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/services/clue_return_destination.dart';

class SessionMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<UserController>() ||
        !Get.find<UserController>().isLoggedIn) {
      var destination = route;
      final uri = Uri.tryParse(route ?? '');
      if (uri?.path == '/living_clues/show' && !uri!.hasQuery) {
        destination = Uri(
            path: '/living_clues/show',
            queryParameters: {'id': Get.parameters['id'] ?? ''}).toString();
      }
      return RouteSettings(name: ClueReturnDestination.login(destination));
    }
    return null;
  }
}
