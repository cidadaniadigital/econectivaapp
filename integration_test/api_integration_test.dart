import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:unisinos_usp_app/main.dart' as app;
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/user_model.dart';
import 'package:unisinos_usp_app/services/auth_user.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

void main() {
  /*************** CAUTION ****************/
  /*  DON'T TESTS CREATE, STORE, UPDATE,  */
  /*  DESTROY or other functions that can */
  /*  change data. RISK OF DEATH!         */
  /*  This is a real API integration!     */
  /****************************************/

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const String email = String.fromEnvironment('E2E_EMAIL');
  const String password = String.fromEnvironment('E2E_PASSWORD');

  Future<AuthUser> _apiLogin() async {
    final String? userPref = Util.prefs.getString('user');

    if (userPref != null && userPref.isNotEmpty) {
      return AuthUser.fromJson(jsonDecode(userPref));
    }

    final UserWebclient webClient = UserWebclient();
    final AuthUser user =
        await webClient.login(mail: email, password: password);
    await Util.prefs.setString('user', jsonEncode(user.toJson()));
    await Get.find<UserController>().savePrefs(user);
    return user;
  }

  testWidgets('user api tests (login + list)', (WidgetTester tester) async {
    expect({'127.0.0.1', 'localhost'},
        contains(Uri.parse(WebClient.apiBaseUrl).host));
    expect(email, isNotEmpty);
    expect(password, isNotEmpty);
    await app.main();

    await tester.pumpAndSettle(const Duration(seconds: 6));
    await _apiLogin();

    final UserWebclient webClient = UserWebclient();

    final List<UserModel> users =
        await webClient.fetchUsers(limit: 10, offset: 0);
    expect(users, isA<List<UserModel>>(),
        reason: 'fetchUsers não retornou lista válida');
    expect(users.isNotEmpty, true, reason: 'fetchUsers retornou lista vazia');
  });
}
