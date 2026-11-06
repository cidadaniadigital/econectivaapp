import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/widgets/editing_preference.dart';
import 'package:get/get.dart';
import 'package:pvalidator/pvalidator.dart';
import 'package:unisinos_usp_app/controllers/auth/profile_controller.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController _controller = Get.find<ProfileController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _filled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(),
        title: const Text('Meu perfil'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          SafeArea(
            top: false,
            child: Obx(() {
              if (_controller.isLoading.value &&
                  _controller.user.value == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final user = _controller.user.value;
              if (user == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Não foi possível carregar seu perfil.',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: _controller.loadProfile,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!_filled) {
                _nameController.text = user.name;
                _emailController.text = user.email;
                _phoneController.text = user.phone ?? '';
                _filled = true;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileHeroCard(
                          name: user.name,
                          email: user.email,
                        ),
                        const SizedBox(height: 18),
                        const EditingPreference(),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xCC0A1C3D), Color(0xB9061430)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0x6646B6EC),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF020814)
                                    .withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dados pessoais',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Atualize suas informações de acesso e contato. O tipo de perfil não é editável aqui.',
                                  style: TextStyle(
                                    color: Color(0xFFA4C0E6),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _ProfileField(
                                  label: 'Nome',
                                  controller: _nameController,
                                  validator: (value) => PValidator([
                                    PRuleRequired(value,
                                        message: 'Obrigatório'),
                                    PRuleMaxString(value, 255,
                                        message: 'Máximo de 255 caracteres'),
                                  ]).val(),
                                ),
                                const SizedBox(height: 14),
                                _ProfileField(
                                  label: 'E-mail',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) => PValidator([
                                    PRuleRequired(value,
                                        message: 'Obrigatório'),
                                    PRuleEmail(value,
                                        message: 'Informe um e-mail válido'),
                                  ]).val(),
                                ),
                                const SizedBox(height: 14),
                                _ProfileField(
                                  label: 'Telefone',
                                  controller: _phoneController,
                                ),
                                const SizedBox(height: 14),
                                _ProfileField(
                                  label: 'Nova senha (opcional)',
                                  controller: _passwordController,
                                  obscureText: true,
                                  validator: (value) {
                                    final text = value?.trim() ?? '';
                                    if (text.isEmpty) return null;
                                    if (text.length < 6) {
                                      return 'Informe ao menos 6 caracteres';
                                    }
                                    if (text.length > 255) {
                                      return 'Máximo de 255 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                _ProfileField(
                                  label: 'Confirmar nova senha',
                                  controller: _confirmPasswordController,
                                  obscureText: true,
                                  validator: (value) {
                                    final password =
                                        _passwordController.text.trim();
                                    final confirm = value?.trim() ?? '';
                                    if (password.isEmpty && confirm.isEmpty) {
                                      return null;
                                    }
                                    if (password != confirm) {
                                      return 'As senhas não coincidem';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 22),
                                Obx(() {
                                  final loading = _controller.isSaving.value;
                                  return SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: loading ? null : _submit,
                                      child: Text(
                                        loading
                                            ? 'Salvando alterações...'
                                            : 'Salvar alterações',
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final saved = await _controller.saveProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      password: _passwordController.text.trim().isEmpty
          ? null
          : _passwordController.text.trim(),
    );

    if (saved) {
      _passwordController.clear();
      _confirmPasswordController.clear();
      if (mounted) setState(() {});
    }
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xE80B2C5A), Color(0xD3051632)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x2949C3F8)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF1C7FCC),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Meu perfil',
                  style: TextStyle(
                    color: Color(0xFF57D2FF),
                    fontSize: 13,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: Color(0xFFA6C5EF),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }
}
