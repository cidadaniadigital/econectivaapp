import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/node_link_model.dart';
import 'package:unisinos_usp_app/webclients/node_link_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';
import 'package:unisinos_usp_app/utils/safe_get_snackbar.dart';

class NodeLinkCreateController extends GetxController {
  final NodeLinkWebclient _webclient = NodeLinkWebclient();

  final RxBool isLoading = false.obs;

  Future<bool> save(NodeLinkModel model) async {
    try {
      isLoading.value = true;
      await _webclient.create(model);
      SafeGetSnackbar.success('Ligação salva com sucesso.');
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível salvar a ligação.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
