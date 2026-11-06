import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/widgets/clue_media.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:unisinos_usp_app/widgets/clue_integrations.dart';
import 'package:unisinos_usp_app/utils/quill_document_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class LivingClueDescriptionView extends StatefulWidget {
  const LivingClueDescriptionView({
    required this.plainText,
    this.delta,
    this.clueId,
    super.key,
  });

  final int? clueId;
  final String plainText;
  final String? delta;

  @override
  State<LivingClueDescriptionView> createState() =>
      _LivingClueDescriptionViewState();
}

class _LivingClueDescriptionViewState extends State<LivingClueDescriptionView> {
  late final QuillController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = QuillController(
      document: QuillDocumentUtils.fromStored(
        delta: widget.delta,
        plainText: widget.plainText,
      ),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  void didUpdateWidget(covariant LivingClueDescriptionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.delta != widget.delta ||
        oldWidget.plainText != widget.plainText) {
      _controller.document = QuillDocumentUtils.fromStored(
        delta: widget.delta,
        plainText: widget.plainText,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuillEditor.basic(
          controller: _controller,
          focusNode: _focusNode,
          config: QuillEditorConfig(
            embedBuilders: const [ClueVideoBuilder(), ClueIntegrationBuilder()],
            unknownEmbedBuilder: const UnknownClueEmbedBuilder(),
            showCursor: false,
            onLaunchUrl: (url) => _openUrl(context, url),
          ),
        ),
        ClueLinkPreviews(controller: _controller, clueId: widget.clueId),
      ],
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível abrir este link.')),
    );
  }
}
