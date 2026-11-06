import 'package:get/get.dart';
import 'package:unisinos_usp_app/bindings/biome_binding.dart';
import 'package:unisinos_usp_app/screens/biome/biome_create_screen.dart';
import 'package:unisinos_usp_app/screens/biome/biome_index_screen.dart';
import 'package:unisinos_usp_app/screens/biome/biome_update_screen.dart';

List<GetPage> biomeRoutes() => [
  GetPage(
    name: '/biomes',
    page: () => BiomeIndexScreen(),
    binding: BiomeIndexBinding(),
  ),
  GetPage(
    name: '/biomes/create',
    page: () => const BiomeCreateScreen(),
    binding: BiomeCreateBinding(),
  ),
  GetPage(
    name: '/biomes/update',
    page: () => const BiomeUpdateScreen(),
    binding: BiomeUpdateBinding(),
  ),
];
