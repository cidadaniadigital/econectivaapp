import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/themes/app_theme.dart';

/// A recoverable startup failure must remain visible even before GetX exists.
class AppStartupFailure extends StatefulWidget {
  const AppStartupFailure(
      {super.key, required this.onRetry, this.routeName = '/'});
  final String routeName;
  final Future<void> Function() onRetry;
  @override
  State<AppStartupFailure> createState() => _AppStartupFailureState();
}

class _AppStartupFailureState extends State<AppStartupFailure> {
  bool _busy = false;
  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onRetry();
    } catch (_) {
      // Keep the same recovery action if initialization is still unavailable.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'USP App',
        theme: AppTheme.theme,
        initialRoute: widget.routeName,
        onGenerateInitialRoutes: (name) => [
          MaterialPageRoute<void>(
              settings: RouteSettings(name: name), builder: _page)
        ],
        onGenerateRoute: (settings) =>
            MaterialPageRoute<void>(settings: settings, builder: _page),
      );

  Widget _page(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 48),
                    const SizedBox(height: 24),
                    const Text('Não foi possível iniciar o app',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    const Text('Verifique sua conexão e tente novamente.'),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _retry,
                      child: Text(
                          _busy ? 'Tentando novamente...' : 'Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
