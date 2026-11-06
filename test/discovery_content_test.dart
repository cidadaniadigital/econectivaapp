import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/models/category_model.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/widgets/discovery_content.dart';

void main() {
  for (final width in [320.0, 768.0, 1280.0]) {
    testWidgets(
        'discovery at $width uses real categories and chronological dates',
        (tester) async {
      tester.view.physicalSize = Size(width, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final search = TextEditingController();
      addTearDown(search.dispose);
      int? category;
      const type = CategoryModel(
          id: 7,
          name: 'Pesquisas do território',
          type: CategoryType.online,
          colorHex: '#43D4C2',
          metadataTags: '');
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: DiscoveryContent(
                      items: [
            LivingClueModel(
                id: 1,
                name: 'Registro antigo',
                categoryId: 7,
                category: type,
                createdAt: DateTime(2025, 1, 1)),
            LivingClueModel(
                id: 2,
                name: 'Registro novo',
                categoryId: 7,
                category: type,
                createdAt: DateTime(2026, 10, 29))
          ],
                      search: search,
                      onSearch: () {},
                      onCatalog: () {},
                      onMap: () {},
                      onCategory: (id) => category = id,
                      onOpen: (_) {},
                      personal: const Text('Área pessoal'))))));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      if (width < 700)
        expect(tester.getTopLeft(find.byType(TextField)).dy, lessThan(150));
      expect(tester.takeException(), isNull);
      expect(find.text('Em destaque'), findsNothing);
      final categoryTile =
          find.widgetWithText(ListTile, 'Pesquisas do território');
      expect(categoryTile, findsOneWidget);
      await tester.ensureVisible(categoryTile);
      await tester.tap(categoryTile);
      expect(category, 7);
      expect(find.text('Adicionada em 29/10/2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
