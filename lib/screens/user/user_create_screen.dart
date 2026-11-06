import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/user/user_create_controller.dart';
import 'package:unisinos_usp_app/models/user_model.dart';
import 'package:unisinos_usp_app/screens/user/user_form.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';

class UserCreateScreen extends StatelessWidget {
  const UserCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserCreateController controller = Get.find<UserCreateController>();
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        leading: const SafeBackButton(),
        title: const Text('Novo usuário'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            child: Obx(
              () => UserForm(
                submitLabel: 'Salvar',
                isLoading: controller.isLoading.value,
                requirePassword: true,
                onSubmit: (value) async {
                  final bool saved = await controller.save(
                    UserModel(
                      id: 0,
                      name: value.name,
                      email: value.email,
                      profile: value.profile,
                      phone: value.phone,
                      password: value.password,
                    ),
                  );

                  if (saved && context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
