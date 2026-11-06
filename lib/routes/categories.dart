import 'package:get/get.dart';
import 'package:unisinos_usp_app/bindings/category/category_create_binding.dart';
import 'package:unisinos_usp_app/bindings/category/category_index_binding.dart';
import 'package:unisinos_usp_app/bindings/category/category_update_binding.dart';
import 'package:unisinos_usp_app/screens/category/category_create_screen.dart';
import 'package:unisinos_usp_app/screens/category/category_index_screen.dart';
import 'package:unisinos_usp_app/screens/category/category_update_screen.dart';

List<GetPage> categoryRoutes() => [
      GetPage(
        name: '/categories',
        page: () => CategoryIndexScreen(),
        binding: CategoryIndexBinding(),
        transition: Transition.downToUp,
        transitionDuration: const Duration(milliseconds: 300),
      ),
      GetPage(
        name: '/categories/create',
        page: () => const CategoryCreateScreen(),
        binding: CategoryCreateBinding(),
      ),
      GetPage(
        name: '/categories/update',
        page: () => const CategoryUpdateScreen(),
        binding: CategoryUpdateBinding(),
      ),
    ];
