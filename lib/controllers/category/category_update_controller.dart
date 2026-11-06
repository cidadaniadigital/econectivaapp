import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/category_model.dart';
import 'package:unisinos_usp_app/webclients/category_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class CategoryUpdateController extends GetxController {
  final CategoryWebclient _webclient = CategoryWebclient();

  final Rxn<CategoryModel> category = Rxn<CategoryModel>();
  final RxBool isLoading = false.obs;

  int? categoryId;

  @override
  void onInit() {
    super.onInit();
    categoryId = int.tryParse(Get.parameters['id'] ?? '');
    if (categoryId != null) {
      loadCategory(categoryId!);
    }
  }

  Future<void> loadCategory(int id) async {
    try {
      isLoading.value = true;
      final CategoryModel loaded = await _webclient.fetchById(id);
      category.value = loaded;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao carregar categoria. $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> save({
    required String name,
    required String type,
    required String colorHex,
    String? iconCode,
    String? description,
    required String metadataTags,
  }) async {
    final int? id = category.value?.id ?? categoryId;
    if (id == null) return false;

    final categoryToSave = CategoryModel(
      id: id,
      name: name.trim(),
      type: type.trim(),
      colorHex: colorHex.trim(),
      iconCode: iconCode?.trim().isEmpty == true ? null : iconCode?.trim(),
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      metadataTags: metadataTags.trim(),
    );

    try {
      isLoading.value = true;
      await _webclient.update(categoryToSave);
      Get.successSnackbar('Categoria salva com sucesso.');
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Não foi possível salvar a categoria. $error');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
