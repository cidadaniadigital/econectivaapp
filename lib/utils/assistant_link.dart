import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// The shared provider can cite the other client's known research route.
/// Resolve that reference locally; never treat arbitrary internal paths as routes.
String? resolveAssistantLink(String? href) {
  if (href == null || href.trim().isEmpty) return null;
  final value = href.trim();
  final uri = Uri.tryParse(value.startsWith('#/') ? value.substring(1) : value);
  if (uri == null) return null;
  if (uri.hasScheme) {
    return {'http', 'https'}.contains(uri.scheme) && uri.host.isNotEmpty
        ? uri.toString()
        : null;
  }
  if (uri.hasAuthority || uri.fragment.isNotEmpty) return null;
  final legacy =
      RegExp(r'^/space/research/([1-9][0-9]*)$').firstMatch(uri.path);
  if (legacy != null && uri.query.isEmpty) {
    return '/living_clues/show?id=${legacy.group(1)}';
  }
  if (uri.path == '/living_clues/show' && uri.queryParameters.length == 1) {
    final id = int.tryParse(uri.queryParameters['id'] ?? '');
    if (id != null && id > 0) return '/living_clues/show?id=$id';
  }
  return null;
}

Future<void> openAssistantLink(String? href, BuildContext context) async {
  final target = resolveAssistantLink(href);
  if (target != null) {
    if (target.startsWith('/')) {
      if (ModalRoute.of(context) is PopupRoute) {
        Navigator.of(context).pop();
      }
      Get.toNamed(target);
      return;
    }
    try {
      if (await launchUrl(Uri.parse(target),
          mode: LaunchMode.platformDefault)) {
        return;
      }
    } catch (_) {
      // Report a failed external launch without breaking the conversation.
    }
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir esse link.')));
  }
}
