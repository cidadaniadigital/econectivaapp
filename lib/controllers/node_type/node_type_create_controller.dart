import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/node_type_model.dart';
import 'package:unisinos_usp_app/webclients/node_type_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';
import 'package:unisinos_usp_app/utils/safe_get_snackbar.dart';

class NodeTypeCreateController extends GetxController {
  final NodeTypeWebclient _webclient = NodeTypeWebclient();

  final RxBool isLoading = false.obs;

  Future<bool> save(NodeTypeModel model) async {
    try {
      isLoading.value = true;
      await _webclient.create(model);
      SafeGetSnackbar.success('Tipo de nó salvo com sucesso.');
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível salvar o tipo de nó.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
