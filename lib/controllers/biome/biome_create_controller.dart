import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/biome_model.dart';
import 'package:unisinos_usp_app/webclients/biome_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class BiomeCreateController extends GetxController {
  final BiomeWebclient _webclient = BiomeWebclient();
  final RxBool isLoading = false.obs;

  Future<bool> save(BiomeModel model) async {
    try {
      isLoading.value = true;
      await _webclient.create(model);
      Get.successSnackbar('Bioma salvo com sucesso.');
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Não foi possível salvar o bioma. $error');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
