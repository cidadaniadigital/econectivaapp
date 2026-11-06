import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:unisinos_usp_app/utils/quill_document_utils.dart';
import 'package:unisinos_usp_app/widgets/living_clue_description_editor.dart';

/// One document owns text, formatting and embedded blocks throughout editing.
class RichClueEditor extends StatefulWidget {
  const RichClueEditor(
      {super.key, this.plainText = '', this.delta, required this.onChanged});
  final String plainText;
  final String? delta;
  final void Function(String text, String? delta) onChanged;
  @override
  State<RichClueEditor> createState() => _RichClueEditorState();
}

class _RichClueEditorState extends State<RichClueEditor> {
  late final QuillController controller;
  @override
  void initState() {
    super.initState();
    controller = QuillController(
        document: QuillDocumentUtils.fromStored(
            delta: widget.delta, plainText: widget.plainText),
        selection: const TextSelection.collapsed(offset: 0));
    controller.addListener(_changed);
  }

  void _changed() => widget.onChanged(QuillDocumentUtils.plainText(controller),
      QuillDocumentUtils.encodeDelta(controller));
  @override
  void dispose() {
    controller.removeListener(_changed);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      LivingClueDescriptionEditor(controller: controller);
}
