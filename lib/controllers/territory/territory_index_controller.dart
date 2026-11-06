import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/biome_model.dart';
import 'package:unisinos_usp_app/models/territory_model.dart';
import 'package:unisinos_usp_app/webclients/biome_webclient.dart';
import 'package:unisinos_usp_app/webclients/territory_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class TerritoryIndexController extends GetxController {
  final TerritoryWebclient _webclient = TerritoryWebclient();
  final BiomeWebclient _biomeWebclient = BiomeWebclient();
  final RxList<TerritoryModel> territories = <TerritoryModel>[].obs;
  final RxList<BiomeModel> biomes = <BiomeModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxnInt selectedBiomeId = RxnInt();

  @override
  void onInit() {
    super.onInit();
    loadBiomes();
    loadTerritories();
  }

  Future<void> loadBiomes() async {
    try {
      biomes.assignAll(await _biomeWebclient.fetch());
    } catch (_) {}
  }

  Future<void> loadTerritories() async {
    try {
      isLoading.value = true;
      territories.assignAll(
        await _webclient.fetch(biomeId: selectedBiomeId.value),
      );
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao buscar territórios. $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteTerritory(TerritoryModel model) async {
    try {
      isLoading.value = true;
      await _webclient.delete(model.id);
      territories.removeWhere((item) => item.id == model.id);
      Get.successSnackbar('Território removido com sucesso.');
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao remover território. $error');
    } finally {
      isLoading.value = false;
    }
  }
}
