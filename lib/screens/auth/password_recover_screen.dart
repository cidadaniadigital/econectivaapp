import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pvalidator/pvalidator.dart';
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/widgets/action_button.dart';
import 'package:widgets_spo/widgets_spo.dart';

class RecoverPasswordScreen extends StatelessWidget {
  final UserController _controller = Get.find<UserController>();
  final TextEditingController _mailTextController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  RecoverPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
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
                  Text('Confirme seu email', style: boldTextStyle(size: 22)),
                  Insets.small.height,
                  Text(
                    'Insira o e-mail associado à sua conta e\nenviaremos um e-mail com um link para\nredefinir sua senha',
                    textAlign: TextAlign.center,
                    style: secondaryTextStyle(size: 14),
                  ),
                  Insets.large.height,
                  InputText(
                    hintText: 'Digite seu e-mail',
                    controller: _mailTextController,
                    validator: (string) {
                      return PValidator([
                        PRuleRequired(string, message: 'Obrigatório'.tlt)
                      ]).val();
                    },
                    keyboardType: TextInputType.emailAddress,
                  ),
                  Insets.extraLarge.height,
                  SizedBox(
                    width: double.infinity,
                    child: ActionButton(
                      theme: ActionButtonTheme.blue,
                      title: 'Enviar link',
                      onPressed: _doSendCode,
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

  Future<void> _doSendCode() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (await _controller.sendCode(_mailTextController.text)) {
          Get.toNamed('/code_confirmation',
              parameters: {'email': _mailTextController.text});
        }
      } catch (_) {/* The controller displays the delivery error. */}
    }
  }
}
