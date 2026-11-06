import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/territory_model.dart';
import 'package:unisinos_usp_app/webclients/territory_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class TerritoryCreateController extends GetxController {
  final TerritoryWebclient _webclient = TerritoryWebclient();
  final RxBool isLoading = false.obs;

  Future<bool> save(TerritoryModel model) async {
    try {
      isLoading.value = true;
      await _webclient.create(model);
      Get.successSnackbar('Território salvo com sucesso.');
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar(
        'Erro',
        'Não foi possível salvar o território. $error',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
