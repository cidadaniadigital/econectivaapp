import 'package:get/get.dart';
import 'package:unisinos_usp_app/bindings/sample_binding.dart';
import 'package:unisinos_usp_app/screens/sample/sample_create_screen.dart';
import 'package:unisinos_usp_app/screens/sample/sample_index_screen.dart';
import 'package:unisinos_usp_app/screens/sample/sample_update_screen.dart';

List<GetPage> sampleRoutes() => [
      GetPage(
        name: '/samples',
        page: () => SampleIndexScreen(),
        binding: SampleIndexBinding(),
      ),
      GetPage(
        name: '/samples/create',
        page: () => const SampleCreateScreen(),
        binding: SampleCreateBinding(),
      ),
      GetPage(
        name: '/samples/update',
        page: () => const SampleUpdateScreen(),
        binding: SampleUpdateBinding(),
      ),
    ];
