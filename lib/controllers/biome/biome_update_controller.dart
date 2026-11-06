import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/biome_model.dart';
import 'package:unisinos_usp_app/webclients/biome_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class BiomeUpdateController extends GetxController {
  final BiomeWebclient _webclient = BiomeWebclient();
  final Rxn<BiomeModel> biome = Rxn<BiomeModel>();
  final RxBool isLoading = false.obs;
  int? biomeId;

  @override
  void onInit() {
    super.onInit();
    biomeId = int.tryParse(Get.parameters['id'] ?? '');
    if (biomeId != null) loadBiome(biomeId!);
  }

  Future<void> loadBiome(int id) async {
    try {
      isLoading.value = true;
      biome.value = await _webclient.fetchById(id);
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao carregar bioma. $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> save(BiomeModel model) async {
    try {
      isLoading.value = true;
      await _webclient.update(model);
      Get.successSnackbar('Bioma atualizado com sucesso.');
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
