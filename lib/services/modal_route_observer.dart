import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Global controls must stay behind dialogs, dropdowns and modal sheets.
class ModalRouteObserver extends NavigatorObserver {
  static final instance = ModalRouteObserver();
  final popupVisible = false.obs;
  var _revision = 0;

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    final revision = ++_revision;
    final visible = topRoute is PopupRoute;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_revision == revision) popupVisible.value = visible;
    });
  }
}
