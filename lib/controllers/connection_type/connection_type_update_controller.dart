import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/connection_type_model.dart';
import 'package:unisinos_usp_app/webclients/connection_type_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class ConnectionTypeUpdateController extends GetxController {
  final ConnectionTypeWebclient _webclient = ConnectionTypeWebclient();

  final Rxn<ConnectionTypeModel> connectionType = Rxn<ConnectionTypeModel>();
  final RxBool isLoading = false.obs;

  int? connectionTypeId;

  @override
  void onInit() {
    super.onInit();
    connectionTypeId = int.tryParse(Get.parameters['id'] ?? '');
    if (connectionTypeId != null) {
      loadConnectionType(connectionTypeId!);
    }
  }

  Future<void> loadConnectionType(int id) async {
    try {
      isLoading.value = true;
      connectionType.value = await _webclient.fetchById(id);
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao carregar tipo de conexão. $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> save(ConnectionTypeModel model) async {
    final int? id = model.id == 0 ? connectionType.value?.id ?? connectionTypeId : model.id;
    if (id == null) return false;
    model.id = id;

    try {
      isLoading.value = true;
      await _webclient.update(model);
      Get.successSnackbar('Tipo de conexão salvo com sucesso.');
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Não foi possível salvar o tipo de conexão. $error');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
