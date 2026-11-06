import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/node_model.dart';
import 'package:unisinos_usp_app/webclients/node_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';
import 'package:unisinos_usp_app/utils/safe_get_snackbar.dart';

class NodeUpdateController extends GetxController {
  final NodeWebclient _webclient = NodeWebclient();

  final Rxn<NodeModel> node = Rxn<NodeModel>();
  final RxBool isLoading = false.obs;

  int? nodeId;

  @override
  void onInit() {
    super.onInit();
    nodeId = int.tryParse(Get.parameters['id'] ?? '');
    if (nodeId != null) {
      loadNode(nodeId!);
    }
  }

  Future<void> loadNode(int id) async {
    try {
      isLoading.value = true;
      node.value = await _webclient.fetchById(id);
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível carregar o nó.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> save(NodeModel model) async {
    final int? id = model.id == 0 ? node.value?.id ?? nodeId : model.id;
    if (id == null) return false;
    model.id = id;
    try {
      isLoading.value = true;
      await _webclient.update(model);
      SafeGetSnackbar.success('Nó atualizado com sucesso.');
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível atualizar o nó.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
