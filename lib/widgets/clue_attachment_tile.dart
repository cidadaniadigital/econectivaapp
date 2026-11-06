import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/models/file_model.dart';
import 'package:unisinos_usp_app/services/attachment_window.dart';
import 'package:unisinos_usp_app/webclients/file_webclient.dart';
import 'package:url_launcher/url_launcher.dart';

/// Private image previews and downloads use temporary access links from the API.
class ClueAttachmentTile extends StatefulWidget {
  const ClueAttachmentTile({
    super.key,
    required this.file,
    this.onRemove,
    this.client,
  });
  final FileModel file;
  final VoidCallback? onRemove;
  final FileWebclient? client;
  @override
  State<ClueAttachmentTile> createState() => _ClueAttachmentTileState();
}

class _ClueAttachmentTileState extends State<ClueAttachmentTile> {
  bool opening = false;
  Future<Uri>? preview;
  bool get isImage {
    const extensions = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};
    const types = {
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp',
      'image/bmp',
    };
    return widget.file.extension.toLowerCase() != 'link' &&
        (extensions.contains(
              widget.file.extension.toLowerCase().replaceFirst('.', ''),
            ) ||
            types.contains(widget.file.mimeType?.toLowerCase()));
  }

  @override
  void initState() {
    super.initState();
    loadPreview();
  }

  @override
  void didUpdateWidget(ClueAttachmentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.id != widget.file.id ||
        oldWidget.client != widget.client) {
      loadPreview();
    }
  }

  void loadPreview() {
    preview = isImage
        ? (widget.client ?? FileWebclient()).access(widget.file.id)
        : null;
  }

  Widget previewFailure({VoidCallback? retry}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_outlined, color: Color(0xFF9CE7DF)),
          const SizedBox(height: 8),
          const Text(
            'Não foi possível exibir a imagem.',
            textAlign: TextAlign.center,
          ),
          TextButton.icon(
            onPressed: retry ?? () => setState(loadPreview),
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    ),
  );

  Widget image(Uri uri, {VoidCallback? retry}) => Image.network(
    uri.toString(),
    fit: BoxFit.contain,
    // The presigned URL authenticates the request. An HTML image also works
    // when a legacy S3 bucket does not expose cross-origin pixel reads.
    webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
    semanticLabel: widget.file.name ?? 'Imagem anexada à pista',
    errorBuilder: (context, error, stack) => previewFailure(retry: retry),
    loadingBuilder: (_, child, progress) => progress == null
        ? child
        : const Center(child: CircularProgressIndicator()),
  );

  Future<void> enlarge() async {
    if (!isImage) return;
    var dialogPreview = (widget.client ?? FileWebclient()).access(
      widget.file.id,
    );
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, updateDialog) {
          void retry() => updateDialog(() {
            dialogPreview = (widget.client ?? FileWebclient()).access(
              widget.file.id,
            );
          });
          return Dialog(
            backgroundColor: const Color(0xFF071320),
            insetPadding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 1200,
              height: MediaQuery.sizeOf(dialogContext).height * .88,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.file.name ?? 'Imagem da pista',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Fechar imagem',
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<Uri>(
                      future: dialogPreview,
                      builder: (_, snapshot) => snapshot.hasError
                          ? previewFailure(retry: retry)
                          : snapshot.hasData
                          ? InteractiveViewer(
                              minScale: 1,
                              maxScale: 5,
                              child: SizedBox.expand(
                                child: image(snapshot.data!, retry: retry),
                              ),
                            )
                          : const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> open() async {
    if (opening) return;
    final window = AttachmentWindow.reserve();
    setState(() => opening = true);
    try {
      final uri = await (widget.client ?? FileWebclient()).access(
        widget.file.id,
      );
      if (window?.navigate(uri) != true &&
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw const AttachmentException(
          'Não foi possível abrir o arquivo. Verifique o bloqueio de novas janelas.',
        );
      }
    } catch (error) {
      window?.close();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is AttachmentException
                  ? error.message
                  : 'Não foi possível acessar o arquivo. Tente novamente.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.file;
    final size = file.size;
    final sizeLabel = size == null || size <= 0
        ? null
        : size < 1024
        ? '$size bytes'
        : size < 1024 * 1024
        ? '${(size / 1024).toStringAsFixed(1)} KB'
        : '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    final tile = ListTile(
      leading: Icon(
        file.extension == 'link'
            ? Icons.link
            : Icons.insert_drive_file_outlined,
        color: const Color(0xFF9CE7DF),
      ),
      title: Text(
        file.name ?? 'Arquivo da pista',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        sizeLabel != null
            ? '${file.extension.toUpperCase()} · $sizeLabel'
            : file.extension.toUpperCase(),
      ),
      onTap: isImage
          ? enlarge
          : opening
          ? null
          : open,
      trailing: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (opening)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            if (isImage)
              IconButton(
                tooltip: 'Ampliar imagem',
                onPressed: enlarge,
                icon: const Icon(Icons.zoom_in),
              ),
            IconButton(
              tooltip: isImage ? 'Baixar arquivo' : 'Acessar arquivo',
              onPressed: open,
              icon: Icon(isImage ? Icons.download_outlined : Icons.open_in_new),
            ),
          ],
          if (widget.onRemove != null)
            IconButton(
              tooltip: 'Remover arquivo',
              onPressed: opening ? null : widget.onRemove,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
    );
    if (!isImage) return tile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: MediaQuery.sizeOf(context).width < 600 ? 220 : 340,
              color: const Color(0xFF050C18),
              child: FutureBuilder<Uri>(
                future: preview,
                builder: (_, snapshot) => snapshot.hasError
                    ? previewFailure()
                    : snapshot.hasData
                    ? InkWell(onTap: enlarge, child: image(snapshot.data!))
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
        ),
        tile,
      ],
    );
  }
}
