import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/category_model.dart';
import 'package:unisinos_usp_app/webclients/category_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class CategoryIndexController extends GetxController {
  final CategoryWebclient _webclient = CategoryWebclient();

  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      isLoading.value = true;
      categories.assignAll(await _webclient.fetch());
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao buscar categorias. $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteCategory(CategoryModel category) async {
    try {
      isLoading.value = true;
      await _webclient.delete(category.id);
      categories.removeWhere((c) => c.id == category.id);
      Get.successSnackbar('Categoria removida com sucesso.');
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao remover categoria. $error');
    } finally {
      isLoading.value = false;
    }
  }
}
