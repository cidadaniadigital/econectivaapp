import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/node_model.dart';
import 'package:unisinos_usp_app/webclients/node_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';
import 'package:unisinos_usp_app/utils/safe_get_snackbar.dart';

class NodeCreateController extends GetxController {
  final NodeWebclient _webclient = NodeWebclient();

  final RxBool isLoading = false.obs;

  Future<bool> save(NodeModel model) async {
    try {
      isLoading.value = true;
      await _webclient.create(model);
      SafeGetSnackbar.success('Nó salvo com sucesso.');
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível salvar o nó.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
