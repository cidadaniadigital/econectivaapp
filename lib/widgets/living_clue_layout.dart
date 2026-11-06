import 'package:unisinos_usp_app/widgets/app_page_viewport.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shared reading and authoring width for living clues.
abstract final class LivingClueLayout {
  static const double maxWidth = AppPageViewport.maxWidth;
  static const double previewMaxWidth = 560;

  static EdgeInsets pagePadding(BuildContext context) => EdgeInsets.symmetric(
    vertical: 24,
    horizontal: math.max(16, (MediaQuery.sizeOf(context).width - maxWidth) / 2),
  );
}
