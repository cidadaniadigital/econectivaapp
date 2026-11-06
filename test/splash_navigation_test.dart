import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/screens/splash_screen.dart';

class _User extends UserController {
  int redirects = 0;
  @override
  Future<void> initializeUser() async {}
  @override
  void redirectLoggedUser() {
    redirects++;
  }
}

void main() {
  testWidgets('leaving splash cancels its pending navigation', (tester) async {
    final user = Get.put<UserController>(_User()) as _User;
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
    expect(user.redirects, 0);
    Get.reset();
  });
}
