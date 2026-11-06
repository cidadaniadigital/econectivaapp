import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/sample_model.dart';
import 'package:unisinos_usp_app/webclients/sample_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class SampleCreateController extends GetxController {
  final SampleWebclient _webclient = SampleWebclient();

  final RxBool isLoading = false.obs;

  Future<bool> save(SampleModel model) async {
    try {
      isLoading.value = true;
      await _webclient.create(model);
      Get.successSnackbar('Sample salvo com sucesso.');
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Não foi possível salvar o sample. $error');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
