import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:pvalidator/pvalidator.dart';
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final UserController _controller = Get.find<UserController>();
  final TextEditingController _mailTextController = TextEditingController();
  final TextEditingController _passwordTextController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _mailTextController.dispose();
    _passwordTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _CidigBackground()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 470),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _BrandBlock(),
                      const SizedBox(height: 26),
                      _LoginCard(
                        formKey: _formKey,
                        mailController: _mailTextController,
                        passwordController: _passwordTextController,
                        onLogin: _doLogin,
                        onGoogleLogin: _doGoogleLogin,
                      ),
                      const SizedBox(height: 24),
                      const _FundingBlock(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doLogin() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _controller.login(
            _mailTextController.text.trim(), _passwordTextController.text);
      } catch (_) {
        // The controller presents the error; keep this form and its return URL.
      }
    }
  }

  Future<void> _doGoogleLogin() async {
    try {
      await _controller.loginGoogle();
    } catch (_) {
      // The controller already presents authentication/provider errors.
    }
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset('assets/logo_atopos.png', height: 86),
        const SizedBox(height: 14),
        const Text(
          'Plataforma para Cidadania Digital',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFD9E7FF),
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Acesse sua conta para explorar conteúdos, trilhas e módulos do ecossistema.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF9DB0D3),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Official agency assets are bundled locally for web and mobile.
class _FundingBlock extends StatelessWidget {
  const _FundingBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Financiamento',
            style: TextStyle(color: Color(0xFF9DB0D3), fontSize: 12)),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 18,
          children: [
            _agency('assets/logo_fapesp.svg', 'FAPESP',
                'Fundação de Amparo à Pesquisa do Estado de São Paulo', false),
            _agency(
                'assets/logo_fapergs.jpg',
                'FAPERGS',
                'Fundação de Amparo à Pesquisa do Estado do Rio Grande do Sul',
                true),
          ],
        ),
      ],
    );
  }

  Widget _agency(
      String asset, String acronym, String name, bool lightBackground) {
    return SizedBox(
      width: 205,
      child: Column(
        children: [
          Container(
            height: 64,
            width: 205,
            decoration: BoxDecoration(
              color: lightBackground ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: asset.endsWith('.svg')
                ? SvgPicture.asset(asset,
                    fit: BoxFit.contain, semanticsLabel: '$acronym — $name')
                : Image.asset(asset,
                    fit: BoxFit.contain, semanticLabel: '$acronym — $name'),
          ),
          const SizedBox(height: 8),
          Text(name,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9DB0D3), fontSize: 11)),
        ],
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.mailController,
    required this.passwordController,
    required this.onLogin,
    required this.onGoogleLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController mailController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;
  final Future<void> Function() onGoogleLogin;

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFF1B3E6F);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      decoration: BoxDecoration(
        color: const Color(0xCC06142F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x5E020814),
            blurRadius: 34,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Entrar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use seu e-mail institucional ou conta cadastrada.',
              style: TextStyle(
                color: Color(0xFFAFC3E6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            _CidigTextField(
              hintText: 'Digite seu e-mail',
              controller: mailController,
              keyboardType: TextInputType.emailAddress,
              validator: (string) {
                return PValidator([
                  PRuleRequired(string, message: 'Obrigatório'.tr),
                ]).val();
              },
            ),
            const SizedBox(height: 12),
            _CidigTextField(
              hintText: 'Senha',
              controller: passwordController,
              obscureText: true,
              validator: (string) {
                return PValidator([
                  PRuleRequired(string, message: 'Obrigatório'.tr),
                ]).val();
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Get.toNamed('/recover_password'),
                child: const Text(
                  'Esqueceu a senha?',
                  style: TextStyle(
                      color: Color(0xFF91AEE3), fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 6),
            _PrimaryButton(
              label: 'Entrar',
              onTap: onLogin,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onGoogleLogin,
              icon: SvgPicture.asset('assets/google_icon.svg',
                  width: 18, height: 18),
              label: const Text(
                'Continuar com Google',
                style: TextStyle(
                  color: Color(0xFFE4EDFD),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: Color(0xFF274E83)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                backgroundColor: const Color(0xCC0B1E42),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Não possui uma conta?',
                    style: TextStyle(color: Color(0xFF9DB0D3))),
                TextButton(
                  onPressed: () => Get.toNamed('/create_account'),
                  child: const Text(
                    'Cadastrar',
                    style: TextStyle(
                      color: Color(0xFF5DCFF8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CidigTextField extends StatelessWidget {
  const _CidigTextField({
    required this.hintText,
    required this.controller,
    required this.validator,
    this.obscureText = false,
    this.keyboardType,
  });

  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF87A0CD), fontSize: 14),
        filled: true,
        fillColor: const Color(0xB30B1E42),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF274E83)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF274E83)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF41B9E8), width: 1.2),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0AA8D7), Color(0xFF1275D2)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CidigBackground extends StatelessWidget {
  const _CidigBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFF0B3B63), Color(0xFF04122C), Color(0xFF020A1C)],
          center: Alignment(-0.05, -0.9),
          radius: 1.28,
          stops: [0.0, 0.48, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -80,
            top: -20,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x2A55E4FF), Color(0x0036C4F4)],
                ),
              ),
            ),
          ),
          Positioned(
            right: -120,
            bottom: -90,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x2B2CD3FF), Color(0x002CD3FF)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
