import 'dart:ui' as ui;
import 'package:unisinos_usp_app/widgets/clue_cover.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/models/file_model.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/webclients/file_webclient.dart';

/// Pending selection is uploaded only after the clue has an ID.
class CoverSelection extends ChangeNotifier {
  PlatformFile? file;
  bool removed = false;
  int? uploadedId;
  Future<void> choose() async {
    final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp']);
    if (result == null) return;
    final candidate = result.files.single;
    if (candidate.size > 25 * 1024 * 1024 || candidate.bytes == null) {
      throw const FormatException('Escolha uma imagem de até 25 MB.');
    }
    final codec = await ui.instantiateImageCodec(candidate.bytes!);
    final frame = await codec.getNextFrame();
    frame.image.dispose();
    codec.dispose();
    file = candidate;
    removed = false;
    uploadedId = null;
    notifyListeners();
  }

  void remove() {
    file = null;
    removed = true;
    uploadedId = null;
    notifyListeners();
  }

  Future<void> apply(LivingClueModel clue) async {
    if (file == null && !removed) return;
    final metadata = Map<String, dynamic>.from(clue.metadata ?? {});
    if (removed) {
      metadata.remove('imagem_capa_arquivo_id');
      metadata[ClueCover.automaticDisabledKey] = true;
      clue.imageUrl = null;
    } else {
      if (uploadedId == null) {
        final uploaded = await FileWebclient().upload(FileModel(
            id: 0,
            extension: file!.extension!.toLowerCase(),
            name: file!.name,
            bytes: file!.bytes,
            size: file!.size,
            livingClueId: clue.id));
        if (uploaded.livingClueId != clue.id || uploaded.id <= 0) {
          throw StateError('Arquivo não foi vinculado à pista.');
        }
        uploadedId = uploaded.id;
      }
      metadata['imagem_capa_arquivo_id'] = uploadedId;
      metadata.remove(ClueCover.automaticDisabledKey);
    }
    clue.metadata = metadata;
  }
}

class ClueCoverEditor extends StatelessWidget {
  const ClueCoverEditor({super.key, required this.selection});
  final CoverSelection selection;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: selection,
      builder: (context, _) => Card(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Imagem de capa',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text(
                        'JPG, PNG, GIF ou WebP, até 25 MB. A capa é salva junto com a pista. Sem capa escolhida, usamos uma imagem anexada ou uma ilustração da categoria. Remover capa mantém os anexos e usa a ilustração.'),
                    if (selection.file != null)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Image.memory(selection.file!.bytes!,
                              height: 150, fit: BoxFit.contain)),
                    if (selection.removed)
                      const Text(
                          'A associação da capa será removida ao salvar.'),
                    Wrap(spacing: 12, children: [
                      OutlinedButton.icon(
                          icon: const Icon(Icons.image_outlined),
                          label: Text(selection.file == null
                              ? 'Escolher imagem'
                              : 'Substituir imagem'),
                          onPressed: () async {
                            try {
                              await selection.choose();
                            } catch (_) {
                              if (context.mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Não foi possível abrir a imagem. Escolha JPG, PNG, GIF ou WebP de até 25 MB.')));
                            }
                          }),
                      TextButton(
                          onPressed: selection.remove,
                          child: const Text('Remover capa')),
                    ])
                  ]))));
}
