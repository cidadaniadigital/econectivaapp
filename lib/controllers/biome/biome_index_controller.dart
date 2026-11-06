import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/biome_model.dart';
import 'package:unisinos_usp_app/webclients/biome_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class BiomeIndexController extends GetxController {
  final BiomeWebclient _webclient = BiomeWebclient();
  final RxList<BiomeModel> biomes = <BiomeModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadBiomes();
  }

  Future<void> loadBiomes() async {
    try {
      isLoading.value = true;
      biomes.assignAll(await _webclient.fetch());
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao buscar biomas. $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteBiome(BiomeModel model) async {
    try {
      isLoading.value = true;
      await _webclient.delete(model.id);
      biomes.removeWhere((item) => item.id == model.id);
      Get.successSnackbar('Bioma removido com sucesso.');
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao remover bioma. $error');
    } finally {
      isLoading.value = false;
    }
  }
}
