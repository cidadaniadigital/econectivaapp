import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/models/category_model.dart';

/// Stable identifiers persisted in category.icon_code; no dynamic font codes.
const categoryMapIcons = <String, (String, IconData)>{
  'pin': ('Pista', Icons.place_outlined),
  'leaf': ('Planta', Icons.eco_outlined),
  'sensor': ('Sensor', Icons.sensors),
  'researcher': ('Pesquisador', Icons.person_search_outlined),
  'book': ('Livro / acervo', Icons.menu_book_outlined),
  'graduate': ('Formação', Icons.school_outlined),
  'institution': ('Instituição', Icons.account_balance_outlined),
  'community': ('Comunidade', Icons.diversity_3_outlined),
  'science': ('Experimento', Icons.science_outlined),
  'water': ('Água', Icons.water_drop_outlined),
  'territory': ('Território', Icons.public),
  'other': ('Outros', Icons.more_horiz),
};

String categoryMapIconKey(CategoryModel? category) {
  final code = category?.iconCode?.trim() ?? '';
  if (categoryMapIcons.containsKey(code)) return code;
  // Recognize legacy numeric codes only within this supported icon catalogue.
  final numeric =
      int.tryParse(code) ??
      int.tryParse(code.replaceFirst('0x', ''), radix: 16);
  for (final entry in categoryMapIcons.entries) {
    if (entry.value.$2.codePoint == numeric) return entry.key;
  }
  switch (category?.name.toLowerCase().trim()) {
    case 'sensor iot':
      return 'sensor';
    case 'planta':
      return 'leaf';
    case 'pesquisador':
      return 'researcher';
    case 'estudante':
      return 'book';
    case 'graduando':
    case 'mestrando':
    case 'doutorando':
    case 'pós-graduando':
      return 'graduate';
    case 'instituição pública':
      return 'institution';
    case 'acervo cidadania digital':
      return 'book';
    case 'vivência de cidadania digital':
      return 'community';
    case 'ambiente de demonstração':
      return 'science';
    case 'outros':
      return 'other';
  }
  switch (category?.type) {
    case CategoryType.living:
      return 'researcher';
    case CategoryType.online:
      return 'book';
    default:
      return 'pin';
  }
}

IconData categoryMapIcon(CategoryModel? category) =>
    categoryMapIcons[categoryMapIconKey(category)]!.$2;

/// Fixed-size, vector-only marker. The 52px interaction target is kept by the
/// map, while the bottom point remains aligned with its previous map anchor.
class CategoryMapMarker extends StatelessWidget {
  const CategoryMapMarker({
    super.key,
    required this.color,
    required this.icon,
    this.selected = false,
  });
  final Color color;
  final IconData icon;
  final bool selected;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 44,
    height: 50,
    child: Stack(
      alignment: Alignment.topCenter,
      children: [
        CustomPaint(
          size: const Size(44, 50),
          painter: _PinPainter(color, selected),
        ),
        Positioned(
          top: 9,
          child: Icon(icon, color: const Color(0xFFF2FCFF), size: 20),
        ),
      ],
    ),
  );
}

class _PinPainter extends CustomPainter {
  const _PinPainter(this.color, this.selected);
  final Color color;
  final bool selected;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(22, 46)
      ..cubicTo(17, 38, 5, 29, 5, 20)
      ..cubicTo(5, -2, 39, -2, 39, 20)
      ..cubicTo(39, 29, 27, 38, 22, 46)
      ..close();
    if (selected) {
      canvas.drawOval(
        const Rect.fromLTWH(7, 40, 30, 8),
        Paint()
          ..color = color.withValues(alpha: .25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawOval(
        const Rect.fromLTWH(7, 40, 30, 8),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: .5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }
    canvas.drawShadow(path, Colors.black, 4, false);
    canvas.drawPath(path, Paint()..color = const Color(0xFF061522));
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: .65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.8,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_PinPainter old) =>
      color != old.color || selected != old.selected;
}
