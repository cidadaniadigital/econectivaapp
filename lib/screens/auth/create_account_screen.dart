import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/widgets/action_button.dart';
import 'package:widgets_spo/widgets_spo.dart';

class CreateAccountScreen extends StatelessWidget {
  final UserController _controller = Get.find<UserController>();
  final TextEditingController _nameTextController = TextEditingController();
  final TextEditingController _mailTextController = TextEditingController();
  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _confirmPasswordTextController = TextEditingController();

  final RxBool isAcceptedTerms = false.obs;

  final _formKey = GlobalKey<FormState>();

  CreateAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 600),
              height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Cadastre-se para se\njuntar a nós', textAlign: TextAlign.center, style: boldTextStyle(size: 22)),
                    Insets.large.height,
                    InputText(
                      hintText: 'Digite seu nome',
                      controller: _nameTextController,
                      validator: (string) {
                        if (string == null || string.isEmpty) {
                          return 'Obrigatório';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.name,
                    ),
                    Insets.large.height,
                    InputText(
                      hintText: 'Digite seu e-mail',
                      controller: _mailTextController,
                      validator: (string) {
                        if (string == null || string.isEmpty) {
                          return 'Obrigatório';
                        }
                        return null;
                      },
                    ),
                    Insets.large.height,
                    InputText(
                      hintText: 'Senha',
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
                      hintText: 'Confirme sua senha',
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
                    Insets.large.height,
                    Obx(() {
                      bool isAccepted = isAcceptedTerms.value;

                      return Row(
                        children: [
                          Checkbox(
                            value: isAccepted,
                            fillColor: MaterialStateProperty.all(Colors.black),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            onChanged: (bool? value) {
                              isAcceptedTerms.value = value!;
                            },
                          ),
                          const Text('Aceito os termos e condições', style: TextStyle(color: Color(0xFF828282))),
                        ],
                      );
                    }),
                    Insets.large.height,
                    SizedBox(
                      width: double.infinity,
                      child: ActionButton(
                        theme: ActionButtonTheme.blue,
                        title: 'Cadastrar',
                        onPressed: () => _doCreateAccount(context),
                      ),
                    ),
                    Insets.extraLarge.height,
                    SizedBox(
                      width: double.infinity,
                      child: ActionButton(
                        theme: ActionButtonTheme.white,
                        icon: SvgPicture.asset('assets/google_icon.svg', width: 20, height: 20),
                        title: 'Continue com Google',
                        onPressed: _doGoogleLogin,
                      ),
                    ),
                    Insets.small.height,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Já tem uma conta?', style: TextStyle(color: Color(0xFF828282))),
                        TextButton(
                          onPressed: () {
                            Get.secureBack();
                          },
                          child: const Text('Entrar', style: TextStyle(color: Color(0xFF828282), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _doCreateAccount(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      if (isAcceptedTerms.value) {
        LoadingDialog.showFuture(
          context,
          _controller.createAccount(
            name: _nameTextController.text,
            email: _mailTextController.text,
            password: _passwordTextController.text,
          ),
        ).then((created) {
          if (created) {
            Get.secureBack();
          }
        });
      } else {
        Get.customSnackbar('Aviso', 'Você deve aceitar os termos e condições para prosseguir.');
      }
    }
  }

  Future<void> _doGoogleLogin() async {
    await _controller.loginGoogle();
  }
}
