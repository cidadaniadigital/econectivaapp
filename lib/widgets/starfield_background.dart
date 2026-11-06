import 'package:flutter/material.dart';

class StarfieldBackground extends StatelessWidget {
  const StarfieldBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF020914), Color(0xFF03162F), Color(0xFF051F3D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -260,
            top: -180,
            child: _AmbientGlow(
              width: 560,
              height: 560,
              gradient: RadialGradient(
                colors: [Color(0x2E2AB9FF), Color(0x0032B9FF)],
              ),
            ),
          ),
          Positioned(
            right: -190,
            top: 90,
            child: _AmbientGlow(
              width: 480,
              height: 480,
              gradient: RadialGradient(
                colors: [Color(0x1D58DFFF), Color(0x0058DFFF)],
              ),
            ),
          ),
          Positioned(
            left: -120,
            bottom: -260,
            child: _AmbientGlow(
              width: 760,
              height: 520,
              gradient: RadialGradient(
                colors: [Color(0x1B00D0FF), Color(0x0000D0FF)],
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0x0D6AE2FF), Color(0x00000000), Color(0x0F57D2FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    required this.width,
    required this.height,
    required this.gradient,
  });

  final double width;
  final double height;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        shape: BoxShape.circle,
      ),
    );
  }
}
