import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/node_link_model.dart';
import 'package:unisinos_usp_app/webclients/node_link_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';
import 'package:unisinos_usp_app/utils/safe_get_snackbar.dart';

class NodeLinkUpdateController extends GetxController {
  final NodeLinkWebclient _webclient = NodeLinkWebclient();

  final Rxn<NodeLinkModel> nodeLink = Rxn<NodeLinkModel>();
  final RxBool isLoading = false.obs;

  int? nodeLinkId;

  @override
  void onInit() {
    super.onInit();
    nodeLinkId = int.tryParse(Get.parameters['id'] ?? '');
    if (nodeLinkId != null) {
      loadNodeLink(nodeLinkId!);
    }
  }

  Future<void> loadNodeLink(int id) async {
    try {
      isLoading.value = true;
      nodeLink.value = await _webclient.fetchById(id);
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível carregar a ligação.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> save(NodeLinkModel model) async {
    final int? id = model.id == 0 ? nodeLink.value?.id ?? nodeLinkId : model.id;
    if (id == null) return false;
    model.id = id;
    try {
      isLoading.value = true;
      await _webclient.update(model);
      SafeGetSnackbar.success('Ligação atualizada com sucesso.');
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível atualizar a ligação.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
