import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/services/clue_map_navigation.dart';

void main() {
  testWidgets('several clue details return to the existing map state',
      (tester) async {
    var mapsCreated = 0;
    await tester.pumpWidget(GetMaterialApp(initialRoute: '/home', getPages: [
      GetPage(name: '/home', page: () => const Scaffold(body: Text('Home'))),
      GetPage(
          name: '/living_clues/map',
          page: () {
            mapsCreated++;
            return const Scaffold(body: Text('Enquadramento preservado'));
          }),
      GetPage(
          name: '/living_clues/show',
          page: () => const Scaffold(body: Text('Pista'))),
    ]));
    await tester.pumpAndSettle();
    Get.toNamed('/living_clues/map');
    await tester.pumpAndSettle();
    Get.toNamed('/living_clues/show', parameters: {'id': '1'});
    await tester.pumpAndSettle();
    Get.toNamed('/living_clues/show',
        parameters: {'id': '2'}, preventDuplicates: false);
    await tester.pumpAndSettle();
    returnToClueMap();
    await tester.pumpAndSettle();
    expect(Get.currentRoute, '/living_clues/map');
    expect(mapsCreated, 1);
    expect(find.text('Enquadramento preservado'), findsOneWidget);
    Get.reset();
  });
}
