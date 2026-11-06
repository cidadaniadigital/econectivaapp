import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/connection_type_model.dart';
import 'package:unisinos_usp_app/webclients/connection_type_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class ConnectionTypeIndexController extends GetxController {
  final ConnectionTypeWebclient _webclient = ConnectionTypeWebclient();

  final RxList<ConnectionTypeModel> connectionTypes = <ConnectionTypeModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadConnectionTypes();
  }

  Future<void> loadConnectionTypes() async {
    try {
      isLoading.value = true;
      connectionTypes.assignAll(await _webclient.fetch());
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao buscar tipos de conexão. $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteConnectionType(ConnectionTypeModel model) async {
    try {
      isLoading.value = true;
      await _webclient.delete(model.id);
      connectionTypes.removeWhere((item) => item.id == model.id);
      Get.successSnackbar('Tipo de conexão removido com sucesso.');
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      Get.customSnackbar('Erro', 'Falha ao remover tipo de conexão. $error');
    } finally {
      isLoading.value = false;
    }
  }
}
