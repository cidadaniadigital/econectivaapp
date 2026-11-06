import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/webclients/preferences_webclient.dart';

/// Keep write forms inaccessible in consultation mode, including direct URLs.
/// API authorization remains authoritative when the user submits a mutation.
class EditingRequired extends StatefulWidget {
  const EditingRequired(
      {super.key,
      required this.builder,
      required this.onConfigure,
      this.loadPreference});
  final WidgetBuilder builder;
  final Future<void> Function() onConfigure;
  final Future<bool> Function()? loadPreference;

  @override
  State<EditingRequired> createState() => _EditingRequiredState();
}

class _EditingRequiredState extends State<EditingRequired> {
  late Future<bool> _allowed;
  Future<bool> _load() =>
      (widget.loadPreference ?? PreferencesWebclient().editingEnabled)();

  @override
  void initState() {
    super.initState();
    _allowed = _load();
  }

  void _refresh() {
    final next = _load();
    setState(() {
      _allowed = next;
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
        future: _allowed,
        builder: (context, snapshot) {
          if (snapshot.data == true) return widget.builder(context);
          return Scaffold(
            appBar: AppBar(title: const Text('Criação e edição')),
            body: Center(
                child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: snapshot.connectionState != ConnectionState.done
                    ? const CircularProgressIndicator()
                    : Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(snapshot.hasError
                            ? 'Não foi possível verificar sua preferência de edição.'
                            : 'Criação e edição desativadas.'),
                        const SizedBox(height: 16),
                        if (snapshot.hasError)
                          FilledButton(
                              onPressed: _refresh,
                              child: const Text('Tentar novamente'))
                        else ...[
                          const Text(
                              'Ative criação e edição em Meu perfil para alterar conteúdos.'),
                          const SizedBox(height: 16),
                          FilledButton(
                              onPressed: () async {
                                await widget.onConfigure();
                                if (mounted) _refresh();
                              },
                              child: const Text('Meu perfil')),
                        ],
                      ]),
              ),
            )),
          );
        },
      );
}
