import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:widgets_spo/widgets_spo.dart';

class SafeGetSnackbar {
  static BuildContext? get _context => Get.context ?? Get.overlayContext;

  static bool get _hasOverlay {
    final context = _context;
    if (context == null) return false;
    return Overlay.maybeOf(context, rootOverlay: true) != null;
  }

  static ScaffoldMessengerState? get _messenger {
    final context = _context;
    if (context == null) return null;
    return ScaffoldMessenger.maybeOf(context);
  }

  static void success(String message) {
    final messenger = _messenger;
    if (messenger != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    if (_hasOverlay) {
      Get.successSnackbar(message);
    }
  }

  static void error(String title, String message) {
    final messenger = _messenger;
    if (messenger != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('$title\n$message'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    if (_hasOverlay) {
      Get.customSnackbar(title, message);
    }
  }
}
