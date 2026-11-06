import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/clue_connection_model.dart';
import 'package:unisinos_usp_app/webclients/clue_connection_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class ClueConnectionCreateController extends GetxController {
  final ClueConnectionWebclient _webclient = ClueConnectionWebclient();

  final RxBool isLoading = false.obs;

  Future<bool> save(ClueConnectionModel model) async {
    try {
      isLoading.value = true;
      await _webclient.create(model);
      Get.successSnackbar('Conexão salva com sucesso.');
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Não foi possível salvar a conexão. $error');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
