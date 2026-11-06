import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/clue_connection_model.dart';
import 'package:unisinos_usp_app/webclients/clue_connection_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class ClueConnectionUpdateController extends GetxController {
  final ClueConnectionWebclient _webclient = ClueConnectionWebclient();

  final Rxn<ClueConnectionModel> connection = Rxn<ClueConnectionModel>();
  final RxBool isLoading = false.obs;

  int? connectionId;

  @override
  void onInit() {
    super.onInit();
    connectionId = int.tryParse(Get.parameters['id'] ?? '');
    if (connectionId != null) {
      loadConnection(connectionId!);
    }
  }

  Future<void> loadConnection(int id) async {
    try {
      isLoading.value = true;
      connection.value = await _webclient.fetchById(id);
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao carregar conexão. $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> save(ClueConnectionModel model) async {
    final int? id = model.id == 0 ? connection.value?.id ?? connectionId : model.id;
    if (id == null) return false;
    model.id = id;

    try {
      isLoading.value = true;
      await _webclient.update(model);
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
