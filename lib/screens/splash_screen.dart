import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _redirectTimer;
  @override
  void initState() {
    super.initState();
    _redirectTimer = Timer(
      const Duration(seconds: 2),
      () {
        if (mounted) Get.find<UserController>().redirectLoggedUser();
      },
    );
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF031225),
        body: Stack(
          children: [
            const Positioned.fill(child: _SplashBackground()),
            Center(
              child: Image.asset(
                'assets/logo_atopos.png',
                width: 260,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF020914), Color(0xFF03162F), Color(0xFF051F3D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -220,
            top: -160,
            child: Container(
              width: 500,
              height: 500,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x2E2AB9FF), Color(0x0032B9FF)],
                ),
              ),
            ),
          ),
          Positioned(
            right: -180,
            bottom: -180,
            child: Container(
              width: 520,
              height: 520,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x1D58DFFF), Color(0x0058DFFF)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
