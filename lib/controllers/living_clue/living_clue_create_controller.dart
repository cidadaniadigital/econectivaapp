import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class LivingClueCreateController extends GetxController {
  final LivingClueWebclient _webclient = LivingClueWebclient();

  LivingClueModel? savedModel;
  final RxBool isLoading = false.obs;

  Future<bool> save(LivingClueModel model) async {
    try {
      isLoading.value = true;
      savedModel = await _webclient.create(model);
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
