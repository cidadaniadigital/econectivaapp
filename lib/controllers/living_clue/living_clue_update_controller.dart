import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class LivingClueUpdateController extends GetxController {
  final LivingClueWebclient _webclient = LivingClueWebclient();

  final Rxn<LivingClueModel> livingClue = Rxn<LivingClueModel>();
  final RxBool isLoading = false.obs;

  int? livingClueId;

  @override
  void onInit() {
    super.onInit();
    livingClueId = int.tryParse(Get.parameters['id'] ?? '');
    if (livingClueId != null) {
      loadLivingClue(livingClueId!);
    }
  }

  Future<void> loadLivingClue(int id) async {
    try {
      isLoading.value = true;
      livingClue.value = await _webclient.fetchById(id);
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao carregar pista. $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> save(LivingClueModel model) async {
    final int? id =
        model.id == 0 ? livingClue.value?.id ?? livingClueId : model.id;
    if (id == null) return false;
    model.id = id;

    try {
      isLoading.value = true;
      await _webclient.update(model);
      Get.successSnackbar('Pista salva com sucesso.');
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Não foi possível salvar a pista. $error');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
