import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/node_link_model.dart';
import 'package:unisinos_usp_app/webclients/node_link_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';
import 'package:unisinos_usp_app/utils/safe_get_snackbar.dart';

class NodeLinkIndexController extends GetxController {
  final NodeLinkWebclient _webclient = NodeLinkWebclient();

  final RxList<NodeLinkModel> nodeLinks = <NodeLinkModel>[].obs;
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
      nodeLinks.assignAll(items);
      hasMore.value = items.length == pageSize;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível carregar as ligações agora.');
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
        offset: nodeLinks.length,
        search: _normalizedSearch,
      );
      nodeLinks.addAll(items);
      hasMore.value = items.length == pageSize;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível carregar mais ligações.');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> applySearch(String value) async {
    search.value = value.trim();
    await loadInitial();
  }

  Future<void> deleteNodeLink(NodeLinkModel model) async {
    try {
      isLoading.value = true;
      await _webclient.delete(model.id);
      nodeLinks.removeWhere((item) => item.id == model.id);
      SafeGetSnackbar.success('Ligação removida com sucesso.');
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível remover a ligação.');
    } finally {
      isLoading.value = false;
    }
  }

  String? get _normalizedSearch => search.value.isEmpty ? null : search.value;
}
