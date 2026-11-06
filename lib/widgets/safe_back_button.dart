import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:widgets_spo/widgets_spo.dart';

/// Back button that falls back to app-defined navigation when the stack is empty.
class SafeBackButton extends StatelessWidget {
  const SafeBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () => Get.secureBack(),
    );
  }
}
