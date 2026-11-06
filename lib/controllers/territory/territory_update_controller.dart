import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/territory_model.dart';
import 'package:unisinos_usp_app/webclients/territory_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class TerritoryUpdateController extends GetxController {
  final TerritoryWebclient _webclient = TerritoryWebclient();
  final Rxn<TerritoryModel> territory = Rxn<TerritoryModel>();
  final RxBool isLoading = false.obs;
  int? territoryId;

  @override
  void onInit() {
    super.onInit();
    territoryId = int.tryParse(Get.parameters['id'] ?? '');
    if (territoryId != null) loadTerritory(territoryId!);
  }

  Future<void> loadTerritory(int id) async {
    try {
      isLoading.value = true;
      territory.value = await _webclient.fetchById(id);
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao carregar território. $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> save(TerritoryModel model) async {
    try {
      isLoading.value = true;
      await _webclient.update(model);
      Get.successSnackbar('Território atualizado com sucesso.');
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
