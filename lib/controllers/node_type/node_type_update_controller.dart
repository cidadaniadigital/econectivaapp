import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/node_type_model.dart';
import 'package:unisinos_usp_app/webclients/node_type_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';
import 'package:unisinos_usp_app/utils/safe_get_snackbar.dart';

class NodeTypeUpdateController extends GetxController {
  final NodeTypeWebclient _webclient = NodeTypeWebclient();

  final Rxn<NodeTypeModel> nodeType = Rxn<NodeTypeModel>();
  final RxBool isLoading = false.obs;

  int? nodeTypeId;

  @override
  void onInit() {
    super.onInit();
    nodeTypeId = int.tryParse(Get.parameters['id'] ?? '');
    if (nodeTypeId != null) {
      loadNodeType(nodeTypeId!);
    }
  }

  Future<void> loadNodeType(int id) async {
    try {
      isLoading.value = true;
      nodeType.value = await _webclient.fetchById(id);
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível carregar o tipo de nó.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> save(NodeTypeModel model) async {
    final int? id = model.id == 0 ? nodeType.value?.id ?? nodeTypeId : model.id;
    if (id == null) return false;
    model.id = id;
    try {
      isLoading.value = true;
      await _webclient.update(model);
      SafeGetSnackbar.success('Tipo de nó atualizado com sucesso.');
      return true;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível atualizar o tipo de nó.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
