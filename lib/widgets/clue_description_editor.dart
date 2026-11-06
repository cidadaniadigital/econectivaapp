import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/widgets/rich_clue_editor.dart';

/// Compatibility entry point for forms already persisting a Quill Delta.
class ClueDescriptionEditor extends StatelessWidget {
  const ClueDescriptionEditor(
      {super.key, required this.delta, required this.onChanged});
  final String delta;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => RichClueEditor(
      delta: delta, onChanged: (_, updated) => onChanged(updated ?? '[]'));
}
