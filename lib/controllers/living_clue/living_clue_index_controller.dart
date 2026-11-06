import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/category_model.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/webclients/category_webclient.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class LivingClueIndexController extends GetxController {
  final LivingClueWebclient _webclient = LivingClueWebclient();
  final CategoryWebclient _categoryWebclient = CategoryWebclient();

  final RxList<LivingClueModel> livingClues = <LivingClueModel>[].obs;
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxnInt selectedCategoryId = RxnInt();

  @override
  void onInit() {
    super.onInit();
    loadFilters();
    loadLivingClues();
  }

  Future<void> loadFilters() async {
    try {
      categories.assignAll(await _categoryWebclient.fetch());
    } catch (_) {}
  }

  Future<void> loadLivingClues() async {
    try {
      isLoading.value = true;
      livingClues.assignAll(
        await _webclient.fetch(
          categoryId: selectedCategoryId.value,
        ),
      );
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao buscar pistas. $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteLivingClue(LivingClueModel model) async {
    try {
      isLoading.value = true;
      await _webclient.delete(model.id);
      livingClues.removeWhere((item) => item.id == model.id);
      Get.successSnackbar('Pista removida com sucesso.');
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao remover pista. $error');
    } finally {
      isLoading.value = false;
    }
  }
}
