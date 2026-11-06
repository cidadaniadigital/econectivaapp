import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';

class CodeConfirmationScreen extends StatefulWidget {
  const CodeConfirmationScreen({super.key});
  @override
  State<CodeConfirmationScreen> createState() => _CodeConfirmationScreenState();
}

class _CodeConfirmationScreenState extends State<CodeConfirmationScreen> {
  final _token = TextEditingController();
  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            leading: const SafeBackButton(),
            title: const Text('Verifique seu e-mail')),
        body: Center(
            child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                      'Abra o link de recuperação enviado para seu e-mail. Se preferir, cole o link ou token abaixo.'),
                  const SizedBox(height: 20),
                  TextField(
                      controller: _token,
                      decoration: const InputDecoration(
                          labelText: 'Link ou token de recuperação')),
                  const SizedBox(height: 20),
                  FilledButton(
                      onPressed: () {
                        var token = _token.text.trim();
                        if (token.isEmpty) {
                          Get.snackbar('Recuperação',
                              'Informe o link ou token recebido.');
                          return;
                        }
                        final uri = Uri.tryParse(token);
                        if (uri != null && uri.hasScheme) {
                          final path = uri.fragment.isNotEmpty
                              ? Uri.parse(uri.fragment).path
                              : uri.path;
                          token =
                              path.split('/').where((s) => s.isNotEmpty).last;
                        }
                        Get.toNamed('/create_password', arguments: token);
                      },
                      child: const Text('Continuar')),
                ]),
          ),
        )),
      );
}
