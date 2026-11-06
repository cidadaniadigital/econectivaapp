import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/node_type_model.dart';
import 'package:unisinos_usp_app/webclients/node_type_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';
import 'package:unisinos_usp_app/utils/safe_get_snackbar.dart';

class NodeTypeIndexController extends GetxController {
  final NodeTypeWebclient _webclient = NodeTypeWebclient();

  final RxList<NodeTypeModel> nodeTypes = <NodeTypeModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxString search = ''.obs;

  static const int pageSize = 20;

  @override
  void onInit() {
    super.onInit();
    loadInitial();
  }

  Future<void> loadInitial() async {
    try {
      isLoading.value = true;
      final items = await _webclient.fetch(limit: pageSize, offset: 0, search: _normalizedSearch);
      nodeTypes.assignAll(items);
      hasMore.value = items.length == pageSize;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível carregar os tipos de nó agora.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore.value) return;
    try {
      isLoadingMore.value = true;
      final items = await _webclient.fetch(
        limit: pageSize,
        offset: nodeTypes.length,
        search: _normalizedSearch,
      );
      nodeTypes.addAll(items);
      hasMore.value = items.length == pageSize;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível carregar mais tipos de nó.');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> applySearch(String value) async {
    search.value = value.trim();
    await loadInitial();
  }

  Future<void> deleteNodeType(NodeTypeModel model) async {
    try {
      isLoading.value = true;
      await _webclient.delete(model.id);
      nodeTypes.removeWhere((item) => item.id == model.id);
      SafeGetSnackbar.success('Tipo de nó removido com sucesso.');
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível remover o tipo de nó.');
    } finally {
      isLoading.value = false;
    }
  }

  String? get _normalizedSearch => search.value.isEmpty ? null : search.value;
}
