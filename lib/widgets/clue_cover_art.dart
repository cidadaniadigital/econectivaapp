import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/models/category_model.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';

/// Local artwork keeps every clue presentable, even offline or without a photo.
class ClueCoverArt extends StatelessWidget {
  const ClueCoverArt({super.key, required this.clue, required this.height});
  final LivingClueModel clue;
  final double height;

  static Color categoryColor(LivingClueModel clue) {
    final hex = (clue.category?.colorHex ?? '').replaceFirst('#', '');
    if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    const palette = [
      Color(0xFF43D4C2),
      Color(0xFF8EACFF),
      Color(0xFFE8B16E),
      Color(0xFFC89DEB),
      Color(0xFF8FCB91)
    ];
    return palette[clue.categoryId.abs() % palette.length];
  }

  static IconData categoryIcon(LivingClueModel clue) {
    final name = (clue.category?.name ?? '').toLowerCase();
    if (name.contains('coleç')) return Icons.collections_bookmark_outlined;
    if (['pessoa', 'pesquisador', 'doutorando', 'mestrando', 'graduando']
        .any(name.contains)) {
      return Icons.person_outline;
    }
    if (name.contains('sensor')) return Icons.sensors_outlined;
    if (name.contains('pesquisa') || name.contains('projeto')) {
      return Icons.science_outlined;
    }
    if (name.contains('vídeo') || name.contains('video')) {
      return Icons.play_circle_outline;
    }
    if (name.contains('livro') ||
        name.contains('artigo') ||
        name.contains('texto') ||
        name.contains('acervo')) {
      return Icons.menu_book_outlined;
    }
    if (name.contains('ambien') ||
        name.contains('natureza') ||
        name.contains('planta')) {
      return Icons.eco_outlined;
    }
    if (clue.category?.type == CategoryType.geographic || clue.hasLocation) {
      return Icons.place_outlined;
    }
    if (clue.category?.type == CategoryType.online) return Icons.language;
    return Icons.hub_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final accent = categoryColor(clue);
    final seed = clue.id == 0
        ? clue.name.runes.fold<int>(0, (value, rune) => value + rune)
        : clue.id;
    return Semantics(
      image: true,
      label: 'Capa ilustrada de ${clue.name}',
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
              gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(const Color(0xFF142137), accent, .28)!,
              const Color(0xFF10192D)
            ],
          )),
          child: Stack(fit: StackFit.expand, children: [
            ExcludeSemantics(
                child: CustomPaint(painter: _CoverPattern(accent, seed))),
            Padding(
              padding: EdgeInsets.all(height < 140 ? 8 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: EdgeInsets.all(height < 140 ? 8 : 14),
                            decoration: BoxDecoration(
                                color: accent.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: accent.withValues(alpha: .3))),
                            child: Icon(categoryIcon(clue),
                                size: height < 140
                                    ? 24
                                    : height < 180
                                        ? 34
                                        : 54,
                                color: Color.lerp(accent, Colors.white, .45)),
                          ))),
                  if (height >= 100) const SizedBox(height: 10),
                  if (height >= 100)
                    Text(clue.category?.name ?? 'Pista viva',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: .6)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _CoverPattern extends CustomPainter {
  const _CoverPattern(this.accent, this.seed);
  final Color accent;
  final int seed;
  @override
  void paint(Canvas canvas, Size size) {
    final center =
        Offset(size.width * (.76 + (seed.abs() % 4) * .04), size.height * .42);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = accent.withValues(alpha: .22);
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(center, size.height * (.24 + i * .18), paint);
    }
    paint
      ..style = PaintingStyle.fill
      ..color = accent.withValues(alpha: .5);
    for (var i = 0; i < 4; i++) {
      final point = Offset(size.width * (.48 + i * .13),
          size.height * (.27 + ((seed.abs() + i) % 3) * .19));
      canvas.drawCircle(point, i == 1 ? 4 : 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(_CoverPattern oldDelegate) =>
      accent != oldDelegate.accent || seed != oldDelegate.seed;
}
