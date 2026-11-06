import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/connection_type_model.dart';
import 'package:unisinos_usp_app/webclients/connection_type_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class ConnectionTypeCreateController extends GetxController {
  final ConnectionTypeWebclient _webclient = ConnectionTypeWebclient();

  final RxBool isLoading = false.obs;

  Future<bool> save(ConnectionTypeModel model) async {
    try {
      isLoading.value = true;
      await _webclient.create(model);
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
