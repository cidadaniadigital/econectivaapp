import 'package:flutter/material.dart';
class AppPageViewport extends StatelessWidget {
  const AppPageViewport({super.key, required this.child});
  static const maxWidth = 1232.0;
  final Widget child;
  @override
  Widget build(BuildContext context) => Center(child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: maxWidth), child: child));
}
