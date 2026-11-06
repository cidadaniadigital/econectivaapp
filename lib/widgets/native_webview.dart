import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Android's hybrid composition keeps the WebGL surface in the native view
/// hierarchy rather than copying a 3D canvas through a Flutter texture.
Widget nativeWebView(WebViewController controller) {
  PlatformWebViewWidgetCreationParams params =
      PlatformWebViewWidgetCreationParams(controller: controller.platform);
  if (controller.platform is AndroidWebViewController) {
    params =
        AndroidWebViewWidgetCreationParams.fromPlatformWebViewWidgetCreationParams(
          params,
          displayWithHybridComposition: true,
        );
  }
  return WebViewWidget.fromPlatformCreationParams(params: params);
}
