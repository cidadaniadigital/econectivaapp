import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/webclients/preferences_webclient.dart';

class EditingPreference extends StatefulWidget {
  const EditingPreference({super.key});
  @override
  State<EditingPreference> createState() => _EditingPreferenceState();
}

class _EditingPreferenceState extends State<EditingPreference> {
  final _client = PreferencesWebclient();
  bool? _enabled;
  bool _busy = false;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final enabled = await _client.editingEnabled();
      if (mounted)
        setState(() {
          _enabled = enabled;
          _failed = false;
        });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _change(bool enabled) async {
    setState(() => _busy = true);
    try {
      await _client.setEditingEnabled(enabled);
      if (mounted) setState(() => _enabled = enabled);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Não foi possível alterar a preferência. Tente novamente.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
        child: _failed
            ? TextButton(
                onPressed: _load,
                child: const Text(
                    'Tentar carregar a preferência de edição novamente'))
            : _enabled == null
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: LinearProgressIndicator())
                : SwitchListTile(
                    title: const Text('Criação e edição'),
                    subtitle: const Text(
                        'Ative para cadastrar e alterar conteúdos. Desative para apenas consultar.'),
                    value: _enabled!,
                    onChanged: _busy ? null : _change,
                  ),
      );
}
