import 'package:flutter/material.dart';
import 'package:pvalidator/pvalidator.dart';
import 'package:unisinos_usp_app/models/user_model.dart';
import 'package:unisinos_usp_app/widgets/action_button.dart';
import 'package:widgets_spo/widgets_spo.dart';

class UserFormValue {
  UserFormValue({
    required this.name,
    required this.email,
    required this.profile,
    this.phone,
    this.password,
  });

  final String name;
  final String email;
  final int profile;
  final String? phone;
  final String? password;
}

class UserForm extends StatefulWidget {
  const UserForm({
    super.key,
    required this.submitLabel,
    required this.isLoading,
    required this.onSubmit,
    this.initialValue,
    this.requirePassword = false,
  });

  final String submitLabel;
  final bool isLoading;
  final bool requirePassword;
  final UserModel? initialValue;
  final Future<void> Function(UserFormValue value) onSubmit;

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  late int _selectedProfile;

  static const List<MapEntry<int, String>> _profiles = [
    MapEntry(10, 'Usuário'),
    MapEntry(40, 'Administrador'),
  ];

  @override
  void initState() {
    super.initState();
    final UserModel? initial = widget.initialValue;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _emailController = TextEditingController(text: initial?.email ?? '');
    _phoneController = TextEditingController(text: initial?.phone ?? '');
    _passwordController = TextEditingController();
    _selectedProfile = _profiles.any((p) => p.key == initial?.profile) ? initial!.profile : 10;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          InputText(
            hintText: 'Nome',
            controller: _nameController,
            validator: (value) => PValidator([
              PRuleRequired(value, message: 'Obrigatório'),
              PRuleMaxString(value, 255, message: 'Máximo de 255 caracteres'),
            ]).val(),
          ),
          Insets.large.height,
          InputText(
            hintText: 'E-mail',
            controller: _emailController,
            validator: (value) => PValidator([
              PRuleRequired(value, message: 'Obrigatório'),
              PRuleEmail(value, message: 'Informe um e-mail válido'),
            ]).val(),
          ),
          Insets.large.height,
          DropdownButtonFormField<int>(
            initialValue: _selectedProfile,
            decoration: const InputDecoration(
              labelText: '',
              border: OutlineInputBorder(),
            ),
            items: _profiles
                .map((entry) => DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(entry.value),
                    ))
                .toList(),
            onChanged: widget.isLoading
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedProfile = value;
                    });
                  },
          ),
          Insets.large.height,
          InputText(
            hintText: 'Telefone',
            controller: _phoneController,
          ),
          Insets.large.height,
          InputText(
            hintText: widget.requirePassword ? 'Senha' : 'Senha (opcional)',
            controller: _passwordController,
            obscureText: true,
            validator: (value) {
              if (widget.requirePassword && (value?.trim().isEmpty ?? true)) {
                return 'Obrigatório';
              }
              if ((value?.trim().length ?? 0) > 255) {
                return 'Máximo de 255 caracteres';
              }
              return null;
            },
          ),
          Insets.extraLarge.height,
          SizedBox(
            width: double.infinity,
            child: ActionButton(
              theme: ActionButtonTheme.blue,
              title: widget.isLoading ? '${widget.submitLabel}...' : widget.submitLabel,
              onPressed: widget.isLoading ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await widget.onSubmit(
      UserFormValue(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        profile: _selectedProfile,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        password: _passwordController.text.trim().isEmpty ? null : _passwordController.text.trim(),
      ),
    );
  }
}
