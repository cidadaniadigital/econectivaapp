import 'package:get/get.dart';
import 'package:unisinos_usp_app/bindings/territory_binding.dart';
import 'package:unisinos_usp_app/screens/territory/territory_create_screen.dart';
import 'package:unisinos_usp_app/screens/territory/territory_index_screen.dart';
import 'package:unisinos_usp_app/screens/territory/territory_update_screen.dart';

List<GetPage> territoryRoutes() => [
  GetPage(
    name: '/territories',
    page: () => TerritoryIndexScreen(),
    binding: TerritoryIndexBinding(),
  ),
  GetPage(
    name: '/territories/create',
    page: () => const TerritoryCreateScreen(),
    binding: TerritoryCreateBinding(),
  ),
  GetPage(
    name: '/territories/update',
    page: () => const TerritoryUpdateScreen(),
    binding: TerritoryUpdateBinding(),
  ),
];
