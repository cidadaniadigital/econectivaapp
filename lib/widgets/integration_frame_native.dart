import 'package:unisinos_usp_app/widgets/native_webview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// External provider content has its own isolated WebView and no app bridge,
/// session token, or permission grants. System permissions remain explicit.
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

class _IntegrationFrameState extends State<IntegrationFrame>
    with WidgetsBindingObserver {
  WebViewController? _controller;
  bool _failed = false, _loading = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _create();
  }

  void _create() {
    if (WebViewPlatform.instance == null) {
      _loading = false;
      return;
    }
    if (![
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.macOS,
    ].contains(defaultTargetPlatform))
      return;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF071623))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted)
              setState(() {
                _loading = true;
                _failed = false;
              });
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted)
              setState(() {
                _failed = true;
                _loading = false;
              });
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri?.scheme == 'https' || request.url == 'about:blank')
              return NavigationDecision.navigate;
            if (request.isMainFrame &&
                uri != null &&
                ['mailto', 'tel', 'hifi'].contains(uri.scheme)) {
              launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              ).catchError((_) => false);
            }
            return NavigationDecision.prevent;
          },
        ),
      );
    _load();
  }

  void _load() {
    if (widget.uri.scheme != 'https') {
      _failed = true;
      _loading = false;
      return;
    }
    _controller?.loadRequest(widget.uri).catchError((Object error) {
      if (mounted)
        setState(() {
          _failed = true;
          _loading = false;
        });
    });
  }

  @override
  void didUpdateWidget(covariant IntegrationFrame old) {
    super.didUpdateWidget(old);
    if (old.uri != widget.uri) _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _controller
          ?.runJavaScript(
            'document.querySelectorAll("video,audio").forEach(function(m){m.pause();});',
          )
          .catchError((_) {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.loadRequest(Uri.parse('about:blank')).catchError((_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.title,
    child: Stack(
      children: [
        if (_controller != null && !_failed)
          Positioned.fill(child: nativeWebView(_controller!)),
        if (_loading && !_failed)
          const Center(child: CircularProgressIndicator()),
        if (_failed || _controller == null)
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.open_in_new, color: Color(0xFF9CE7DF)),
                  const SizedBox(height: 12),
                  const Text(
                    'Não foi possível exibir este conteúdo aqui. Você pode tentar novamente ou abrir na origem.',
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _failed = false;
                        _loading = true;
                      });
                      _load();
                    },
                    child: const Text('Tentar novamente'),
                  ),
                  TextButton(
                    onPressed: () => launchUrl(
                      widget.uri,
                      mode: LaunchMode.externalApplication,
                    ),
                    child: const Text('Abrir no navegador'),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
