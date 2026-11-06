import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unisinos_usp_app/services/clue_qr.dart';
import 'package:unisinos_usp_app/services/save_qr.dart';

class ClueQrDialog extends StatefulWidget {
  const ClueQrDialog({super.key, required this.clueId, required this.name});
  final int clueId;
  final String name;
  @override
  State<ClueQrDialog> createState() => _ClueQrDialogState();
}

class _ClueQrDialogState extends State<ClueQrDialog> {
  late final qr = ClueQr(widget.clueId);
  bool saving = false;
  String? status;
  Future<void> save() async {
    setState(() {
      saving = true;
      status = null;
    });
    try {
      final saved = await saveQrPng(await qr.png(), widget.clueId);
      if (mounted && saved) setState(() => status = 'QR Code salvo em PNG.');
    } catch (_) {
      if (mounted)
        setState(
          () => status = 'Não foi possível salvar o QR Code. Tente novamente.',
        );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Row(
      children: [
        const Expanded(child: Text('QR Code da pista')),
        IconButton(
          tooltip: 'Fechar QR Code',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    ),
    content: SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.name,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Semantics(
            label: 'QR Code para a pista ${widget.name}',
            image: true,
            child: SizedBox.square(
              dimension: (MediaQuery.sizeOf(context).width - 112).clamp(
                140.0,
                280.0,
              ),
              child: CustomPaint(painter: ClueQrPainter(qr)),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Leia com a câmera do celular para acessar esta pista. É necessário entrar na plataforma.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SelectableText(
            qr.url,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
          if (status != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Semantics(
                liveRegion: true,
                child: Text(status!, textAlign: TextAlign.center),
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton.icon(
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: qr.url));
          if (mounted) setState(() => status = 'Link da pista copiado.');
        },
        icon: const Icon(Icons.copy_outlined),
        label: const Text('Copiar link'),
      ),
      FilledButton.icon(
        onPressed: saving ? null : save,
        icon: const Icon(Icons.download_outlined),
        label: Text(saving ? 'Gerando…' : 'Baixar PNG'),
      ),
    ],
  );
}

Future<void> showClueQr(BuildContext context, int id) => showDialog<void>(
  context: context, builder: (_) => ClueQrDialog(clueId: id, name: 'Pista #$id'));
