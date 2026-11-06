import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/widgets/clue_attachment_tile.dart';
import 'package:unisinos_usp_app/models/file_model.dart';
import 'package:unisinos_usp_app/webclients/file_webclient.dart';

class ClueAttachments extends StatefulWidget {
  const ClueAttachments(
      {required this.clueId, this.canEdit = false, super.key});
  final bool canEdit;
  final int clueId;
  @override
  State<ClueAttachments> createState() => _ClueAttachmentsState();
}

class _ClueAttachmentsState extends State<ClueAttachments> {
  final _client = FileWebclient();
  late Future<List<FileModel>> _files;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _files = _client.fetch(livingClueId: widget.clueId);
  }

  void _error(Object error) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível concluir. $error')));
  }

  Future<void> _upload() async {
    if (!widget.canEdit) return;
    try {
      final selection = await FilePicker.platform.pickFiles(withData: true);
      if (selection == null || !mounted) return;
      final file = selection.files.single;
      setState(() => _busy = true);
      await _client.upload(FileModel(
          id: 0,
          extension: file.extension ?? '',
          name: file.name,
          bytes: file.bytes,
          size: file.size,
          livingClueId: widget.clueId));
      if (mounted)
        setState(() => _files = _client.fetch(livingClueId: widget.clueId));
    } catch (error) {
      _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(FileModel file) async {
    if (!widget.canEdit) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Excluir anexo?'),
                content: Text(file.name ?? 'Arquivo'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Excluir'))
                ]));
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _client.delete(file.id);
      if (mounted)
        setState(() => _files = _client.fetch(livingClueId: widget.clueId));
    } catch (error) {
      _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
          child: Padding(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Anexos', style: TextStyle(fontWeight: FontWeight.w700)),
          FutureBuilder<List<FileModel>>(
              future: _files,
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return TextButton(
                      onPressed: () => setState(() =>
                          _files = _client.fetch(livingClueId: widget.clueId)),
                      child: const Text(
                          'Falha ao carregar anexos. Tentar novamente'));
                if (!snapshot.hasData) return const LinearProgressIndicator();
                if (snapshot.data!.isEmpty)
                  return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Nenhum anexo.'));
                return Column(
                    children: snapshot.data!
                        .map((file) => ClueAttachmentTile(
                            file: file,
                            onRemove: widget.canEdit && !_busy
                                ? () => _delete(file)
                                : null))
                        .toList());
              }),
          if (widget.canEdit)
            OutlinedButton.icon(
                onPressed: _busy ? null : _upload,
                icon: const Icon(Icons.upload_file),
                label: Text(_busy ? 'Aguarde...' : 'Adicionar anexo')),
        ]),
      ));
}
