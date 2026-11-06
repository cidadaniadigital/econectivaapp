import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/widgets/action_button.dart';
import 'package:widgets_spo/widgets_spo.dart';

class CreatePasswordScreen extends StatelessWidget {
  final UserController _controller = Get.find<UserController>();

  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _confirmPasswordTextController =
      TextEditingController();

  final String token = Get.parameters['token'] ??
      (Get.arguments is String ? Get.arguments as String : '');
  final _formKey = GlobalKey<FormState>();

  CreatePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        body: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Crie uma nova senha', style: boldTextStyle(size: 22)),
                  Insets.small.height,
                  Text('Acesse a plataforma',
                      style: secondaryTextStyle(size: 14)),
                  Insets.extraLarge.height,
                  InputText(
                    hintText: 'Crie uma nova senha',
                    controller: _passwordTextController,
                    obscureText: true,
                    validator: (string) {
                      if (string == null || string.isEmpty) {
                        return 'Obrigatório';
                      }
                      return null;
                    },
                  ),
                  Insets.large.height,
                  InputText(
                    hintText: 'Confirme a senha',
                    controller: _confirmPasswordTextController,
                    obscureText: true,
                    validator: (string) {
                      if (string == null || string.isEmpty) {
                        return 'Obrigatório';
                      }
                      if (string != _passwordTextController.text) {
                        return 'As senhas não coincidem';
                      }
                      return null;
                    },
                  ),
                  Insets.extraLarge.height,
                  SizedBox(
                    width: double.infinity,
                    child: ActionButton(
                      theme: ActionButtonTheme.blue,
                      title: 'Registrar',
                      onPressed: _doChangePassword,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _doChangePassword() async {
    if (token.isEmpty) {
      Get.snackbar('Recuperação', 'Abra o link recebido por e-mail.');
      return;
    }
    if (_formKey.currentState!.validate()) {
      try {
        final user = await _controller.recoverPassword(
            token, _passwordTextController.text);

        await _controller.savePrefs(user);
        Get.offAllNamed('/home');
      } catch (_) {
        /* Controller displays the API error without leaving the form. */
      }
    }
  }
}
