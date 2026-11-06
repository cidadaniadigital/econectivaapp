import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/screens/living_clue/living_clue_show_screen.dart';

class _SignedOutUser extends UserController {
  @override
  Future<void> initializeUser() async {}
}

void main() {
  testWidgets('signed-out detail preserves ID in login query', (tester) async {
    Get.put<UserController>(_SignedOutUser());
    await tester.pumpWidget(GetMaterialApp(initialRoute: '/start', getPages: [
      GetPage(name: '/start', page: () => const Scaffold(body: Text('Start'))),
      GetPage(name: '/login', page: () => const Scaffold(body: Text('Login'))),
      GetPage(
          name: '/living_clues/show', page: () => const LivingClueShowScreen()),
    ]));
    await tester.pumpAndSettle();
    Get.offAllNamed('/living_clues/show', parameters: {'id': '8'});
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
    expect(Get.parameters['return'], '/living_clues/show?id=8');
    Get.reset();
  });
}
