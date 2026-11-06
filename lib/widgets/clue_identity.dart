import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'clue_cover.dart';

/// Generic identity block using the approved Cidig composition for every category.
class ClueIdentity extends StatelessWidget {
  const ClueIdentity({super.key, required this.clue, this.canEdit = false});
  final bool canEdit;
  final LivingClueModel clue;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, bounds) {
        final mobile = bounds.maxWidth < 760;
        final introduction =
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('CIDIG / ATOPOS / USP',
              style: TextStyle(
                  fontSize: 12, letterSpacing: 1.5, color: Color(0xFFA1AEC4))),
          const SizedBox(height: 20),
          Text(clue.category?.name ?? 'Categoria ${clue.categoryId}',
              style: const TextStyle(
                  color: Color(0xFF43D4C2), fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(clue.name,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: mobile ? 30 : 40, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          if ((clue.description ?? '').isNotEmpty)
            Text(clue.description!, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 20),
          Wrap(spacing: 12, runSpacing: 12, children: [
            FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF28B50),
                    foregroundColor: const Color(0xFF090F20)),
                onPressed: () => Get.toNamed('/living_clues/${clue.id}/chat',
                    arguments: {'model': clue}),
                icon: const Icon(Icons.forum_outlined),
                label: const Text('Abrir conversa')),
            if (canEdit)
              OutlinedButton.icon(
                  onPressed: () =>
                      Get.toNamed('/living_clues/connect', arguments: clue),
                  icon: const Icon(Icons.hub_outlined),
                  label: const Text('Conectar a outra pista')),
          ]),
        ]);
        final cover = ClueCover(clue: clue, height: mobile ? 230 : 320);
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (clue.metadata?['dados_ficticios'] == true) ...[
                Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: const Color(0xFF29251F),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text(
                        'Demonstração com dados fictícios declarados. Valores e identidades do piloto não representam observações reais.',
                        style: TextStyle(color: Color(0xFFF7B977)))),
                const SizedBox(height: 24),
              ],
              if (mobile) ...[
                introduction,
                const SizedBox(height: 24),
                cover
              ] else
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 6, child: introduction),
                  const SizedBox(width: 40),
                  Expanded(flex: 5, child: cover)
                ]),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
            ]);
      });
}
