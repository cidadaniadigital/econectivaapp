import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class IntegrationFrame extends StatefulWidget {
  const IntegrationFrame({
    super.key,
    required this.uri,
    required this.title,
    this.media = false,
  });
  final Uri uri;
  final String title;
  final bool media;
  @override
  State<IntegrationFrame> createState() => _IntegrationFrameState();
}

class _IntegrationFrameState extends State<IntegrationFrame> {
  static int _next = 0;
  late final String _view = 'onlife-content-${_next++}';
  late final web.HTMLIFrameElement _frame;
  @override
  void initState() {
    super.initState();
    _frame = web.HTMLIFrameElement()
      ..src = widget.uri.toString()
      ..title = widget.title
      ..setAttribute(
        'sandbox',
        'allow-scripts allow-same-origin allow-forms allow-popups allow-popups-to-escape-sandbox allow-downloads'
        '${widget.media ? ' allow-pointer-lock' : ''}',
      )
      ..setAttribute('referrerpolicy', 'strict-origin-when-cross-origin')
      ..allow = widget.media
          ? 'camera; microphone; autoplay; fullscreen; clipboard-write'
          : 'fullscreen; clipboard-write'
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%';
    _frame.setAttribute('allowfullscreen', 'true');
    ui.platformViewRegistry.registerViewFactory(_view, (_) => _frame);
  }

  @override
  void didUpdateWidget(covariant IntegrationFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri) _frame.src = widget.uri.toString();
    _frame.title = widget.title;
  }

  @override
  void dispose() {
    // Stop audio/rendering before disposing the Flutter platform view.
    _frame.src = 'about:blank';
    _frame.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _view);
}
